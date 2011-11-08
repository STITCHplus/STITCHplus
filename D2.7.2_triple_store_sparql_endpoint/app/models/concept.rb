require "net/http"
require "hpricot"
class Concept

  NAMESPACES = {
    "http://www.w3.org/1999/02/22-rdf-syntax-ns#" => "rdf",
    "http://www.w3.org/2000/01/rdf-schema#" => "rdfs",
    "http://purl.org/dc/elements/1.1/" => "dc",
    "http://triplestore.aktors.org/ontology/#" => "ts",
    "http://triplestore.aktors.org/direct/#" => "tsd",
    "http://www.w3.org/2004/02/skos/core#" => "skos",
    "http://www.ontotext.com/" => "onto"
  };



	attr_accessor :uri, :label, :related_concepts, :broader_concepts, :narrower_concepts, :my_details

	def self.find(params = {})
		concepts = []
		if params[:q]
			concepts = Concept.concepts_from_query(%(
				prefix skos: <http://www.w3.org/2004/02/skos/core#>
				PREFIX onto: <http://www.ontotext.com/>
				select distinct ?x ?preflabel
				where { 
				 ?x onto:luceneQuery "#{params[:q].gsub(" ", " AND ")}" .
				 ?x skos:prefLabel ?preflabel .
				} LIMIT 100
			), "'#{params[:q]}' zoeken")
		elsif params[:uri]
			concept = Concept.new(:uri => CGI.unescape(params[:uri]))
		elsif params[:ppn]
			concept = Concept.new(:uri => "http://datao.kb.nl/thesaurus/#{params[:ppn]}")
		end
		return params[:q] ? concepts : concept
	end

	def initialize(params)
		self.uri = params[:uri]
		self.label = params[:label]

		self.details if self.label.nil?
	end

	def all_fields
		fields = []
		q = "SELECT ?pred ?value WHERE { <#{self.uri}> ?pred ?value }"
		cached_query = Digest::SHA2.hexdigest(q.gsub(/\n/, "").gsub(/\s+/, ""))
		query = Query.find_or_create_by_cached_query(:cached_query => cached_query, :sparql_str => q, :name => "details", :is_shown => false)
		doc = File.open("#{RAILS_ROOT}/public/cached_results/#{query.result_file}") {|f| Hpricot::XML(f) }
		(doc/"//result").each {|result| fields << {namespace_for(result.children[1].children[0].innerText) => result.children[3].children[0].innerText}}
		query.destroy
		fields
	end

	def details
		return self.my_details if self.my_details

		self.my_details = []
		q = %(
			select ?pred ?value
			where {
				<#{self.uri}> ?pred ?value
			}
		)
		cached_query = Digest::SHA2.hexdigest(q.gsub(/\n/, "").gsub(/\s+/, ""))
		query = Query.find_or_create_by_cached_query(:cached_query => cached_query, :sparql_str => q, :name => "details", :is_shown => false)
		doc = File.open("#{RAILS_ROOT}/public/cached_results/#{query.result_file}") {|f| Hpricot::XML(f) }

		# pred value
		(doc/"/sparql/results/result").each do |result|
			predicate = (result/"binding").select{|b| b.attributes["name"] == "pred"}.first.get_elements_by_tag_name("uri").first.innerText
			val_bind =  (result/"binding").select{|b| b.attributes["name"] == "value"}.first
			value = ""
			if (elem = val_bind.get_elements_by_tag_name("uri")).length > 0
				value = elem.first.innerText
			elsif(elem = val_bind.get_elements_by_tag_name("literal")).length > 0
				value = elem.first.innerText
			end
			if predicate =~ /prefLabel/
				self.label = value
			else
				self.my_details << {namespace_for(predicate) => value}
			end
		end

#		(doc/"//result").each do |result|
#			if result.children[1].children[0].innerText =~ /prefLabel/
#				self.label = result.children[3].children[0].innerText 
#			elsif !(result.children[1].children[0].innerText =~ /related/) && 
#						!(result.children[1].children[0].innerText =~ /broader/)
#				self.my_details << {namespace_for(result.children[1].children[0].innerText) => result.children[3].children[0].innerText}
#			end
#		end


		query.destroy
	end

	def related
		return self.related_concepts if self.related_concepts

		self.related_concepts = Concept.concepts_from_query(%(
			prefix skos: <http://www.w3.org/2004/02/skos/core#>
			select distinct ?x ?preflabel
			where {
				?x skos:prefLabel ?preflabel .
				<#{self.uri}> skos:related ?x .
			}
		), "'#{self.label}': related outbound")

	end

	def narrower
		return self.broader_concepts if self.broader_concepts

		self.broader_concepts = Concept.concepts_from_query(%(
			prefix skos: <http://www.w3.org/2004/02/skos/core#>
			select distinct ?x ?preflabel
			where {			
				?x skos:prefLabel ?preflabel .
				?x skos:broader <#{self.uri}>
			}
		), "'#{self.label}': broader")
	end

	def broader
		return self.narrower_concepts if self.narrower_concepts

		self.narrower_concepts = Concept.concepts_from_query(%(
			prefix skos: <http://www.w3.org/2004/02/skos/core#>
			select distinct ?x ?preflabel
			where {			
				?x skos:prefLabel ?preflabel .
				<#{self.uri}> skos:broader ?x
			}
		), "'#{self.label}': narrower")
	end

	def delete
		raise "TODO"
		dbh = Mysql.real_connect("localhost", "rdf", "rdf", "3s3_skos")
		res = dbh.query("select DISTINCT hash from symbols where symbols.lexical = \"#{CGI.unescape(self.uri)}\"")
		subject_hash = res.fetch_row.first
		dbh.query("delete from triples where subject = #{subject_hash}") if(subject_hash)
		dbh.close
	end

	def update_attributes(attributes)
		raise "TODO"
		namespaces = attributes.map{|k, v| k.gsub(/:.+/, "") }.uniq
		rdf = "<rdf:RDF " + NAMESPACES.select{|k, v| namespaces.include?(v)}.map{|k, v| "xmlns:#{v}=\"#{k}\""}.join(" ") + ">\n"
		rdf += "<skos:Concept rdf:about=\"#{self.uri}\">\n"
		rdf += attributes.map {|k, values| values.map{|v| v =~ /http:\/\// ? "<#{k} rdf:resource=\"#{v.gsub("&", "&amp;")}\"></#{k}>" : "<#{k}>#{v.gsub("&", "&amp;")}</#{k}>" }.join("\n")}.join("\n")
		rdf += "</skos:Concept></rdf:RDF>"
		tmp = Tempfile.new("record")
		tmp.write(rdf)
		tmp.flush
		self.delete
#		`ts-import -d skos #{tmp.path}`
	end

	private
	def namespace_for(str)
		NAMESPACES.each {|k, v| str.gsub!(k, "#{v}:") }
		str
	end

	def self.concepts_from_query(q = nil, name = "")
		concepts = []
		if(q)
			cached_query = Digest::SHA2.hexdigest(q.gsub(/\n/, "").gsub(/\s+/, ""))
			query = Query.find_or_create_by_cached_query(:cached_query => cached_query, :sparql_str => q, :name => name, :is_shown => false)
			unparsed_concepts = File.open("#{RAILS_ROOT}/public/cached_results/#{query.result_file}") {|f| Hpricot::XML(f) }
			(unparsed_concepts/"//result").each do |result|
#				concepts << Concept.new({:uri => result.children[1].children[0].innerText, :label => result.children[3].children[0].innerText})

      	uri = (result/"binding").select{|b| b.attributes["name"] == "x"}.first.get_elements_by_tag_name("uri").first.innerText
    	  label = (result/"binding").select{|b| b.attributes["name"] == "preflabel"}.first.get_elements_by_tag_name("literal").first.innerText
				concepts << Concept.new({:uri => uri, :label => label})
			end
			query.destroy
		end
		return concepts
	end
end

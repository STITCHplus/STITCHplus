class Cql
	PREFIXES = {
		"skos" => "http://www.w3.org/2004/02/skos/core#",
		"dc" => "http://purl.org/dc/elements/1.1/",
		"rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "onto" => "http://www.ontotext.com/"
	}

	attr_accessor :result_xml, :query_str

	def initialize(cql)
		if cql.blank?
			self.result_xml = "<empty></empty>"
		else
			q = parse_sparql(cql)

			cached_query = Digest::SHA2.hexdigest(q.gsub(/\n/, "").gsub(/\s+/, ""))
			query = Query.find_or_create_by_cached_query(:cached_query => cached_query, :sparql_str => q, :name => "", :is_shown => false)
		
			self.result_xml = File.open("#{RAILS_ROOT}/public/cached_results/#{query.result_file}") {|f| f.read }
			self.query_str = q
		end
	end


	private

	def fetch_statements(cql, statements = [])
		x = cql.match(/\[(.+)\]/).captures[0] if cql =~ /\[/
		statements << cql.gsub(/\[.+\]/, "") unless cql.gsub(/\[.+\]/, "") == ""
		if cql =~ /\[/
			fetch_statements(x, statements)
		end
		statements
	end

	def fetch_prefix(cql)
		x = cql.scan(/([a-zA-Z]+)\./).map{|cap| cap[0]}
		x[0]
	end

	def split_statement(s)
		s.gsub("=", " = ").split(/\s+/)
	end

	def fetch_words(statement)
		object = statement.match(/\"(.+)\"/).captures if statement =~ /\"/
		if object
			(predicate, operator) = split_statement(statement) 
		else
			(predicate, operator, object) = split_statement(statement)
		end
		[predicate, operator, object]
	end

	def parse_sparql(cql)
		prefixes = [] 
		statements = fetch_statements(cql)
		sparql = ""
#		prefixes.each {|prefix| sparql += "PREFIX #{prefix}: <#{PREFIXES[prefix]}>\n" }

		sparql += "SELECT DISTINCT ?binding0\nWHERE {\n"
		statements.each_with_index do |nested_statement, i|
			nested_statement.split(/ and /).each do |statement|
				(predicate, operator, object) = fetch_words(statement)
				prefixes << fetch_prefix(predicate)
				if object 
					if object =~ /\</
						if predicate == "skos.narrower"
							sparql += "  #{object} skos:broader ?binding#{i} .\n"
						else
							sparql += "  ?binding#{i} #{predicate.gsub(".", ":")} #{object} .\n"
						end
					elsif predicate == "skos.prefLabel"
						sparql += "  ?binding#{i} #{predicate.gsub(".", ":")} ?lbl#{i} .\n"
						sparql += "  FILTER regex(?lbl#{i}, \"^#{object}\", \"i\") .\n"
					else
						sparql += "  ?binding#{i} #{predicate.gsub(".", ":")} \"#{object}\"\n"
					end
				else
					if predicate == "skos.narrower"
						sparql += "  ?binding#{i+1} skos:broader ?binding#{i} .\n"
					else
						sparql += "  ?binding#{i} #{predicate.gsub(".", ":")} ?binding#{i+1} .\n"
					end
				end
			end
		end
		sparql += "}\nLIMIT 100"
		prefixes.uniq.each {|prefix| sparql = "PREFIX #{prefix}: <#{PREFIXES[prefix]}>\n" + sparql }
		return sparql
	end

end

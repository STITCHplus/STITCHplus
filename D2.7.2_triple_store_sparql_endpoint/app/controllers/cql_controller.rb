require "json"
class CqlController < ApplicationController
	def index
		@cql = Cql.new(params[:q])
		@results = Hpricot.XML(@cql.result_xml)
		@formatted_results = format_results(@results, params[:fields]) if params[:fields]
		respond_to do |format|
			format.html
			format.xml {render :xml => @cql.result_xml }
			format.json do 
				if params[:fields]
					render :text => JSON(@formatted_results)
				else
					render :text => JSON((@results/'//uri').map{|uri| uri.innerText.gsub("http://datao.kb.nl/thesaurus/", "")}) 
				end
			end
		end
	end

	private
	def format_results(results, fieldstr)
		formatted_results = []
		fields = fieldstr.split(",")
		res_a = (results/'//uri')
		res_a.each do |result|
			if fields.length > 1
				formatted_results << {}
				formatted_results.last["uri"] = result.innerText if fields.include?("uri")
				formatted_results.last["ppn"] = result.innerText.sub("http://datao.kb.nl/thesaurus/", "") if fields.include?("ppn")
				formatted_results.last["label"] = get_label(result) if fields.include?("label")
			else
				formatted_results << result.innerText if fields.first == "uri"
				formatted_results << result.innerText.sub("http://datao.kb.nl/thesaurus/", "") if fields.first == "ppn"
				formatted_results << get_label(result) if fields.first == "label"
			end
		end
		return formatted_results			
	end

	def get_uri(result); return result.innerText; end
	def get_ppn(result); return result.innerText.gsub("http://datao.kb.nl/thesaurus/"); end

	def get_label(result)
		q = %(PREFIX skos: <http://www.w3.org/2004/02/skos/core#>\nSELECT ?lbl WHERE { <#{result.innerText}> skos:prefLabel ?lbl } LIMIT 1)
		cached_query = Digest::SHA2.hexdigest(q.gsub(/\n/, "").gsub(/\s+/, ""))
		query = Query.find_or_create_by_cached_query(:cached_query => cached_query, :sparql_str => q, :name => "", :is_shown => false)		
		xml = File.open("#{RAILS_ROOT}/public/cached_results/#{query.result_file}") {|f| f.read }
		parsed = Hpricot.XML(xml)
		return (parsed/'//literal').first.innerText.sub('"', "&quot;")
	end
end

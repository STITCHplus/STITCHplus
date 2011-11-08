require "ruby-sesame"

class Query < ActiveRecord::Base
	has_one :result_set
	validates_presence_of :sparql_str

	before_create :run
	before_destroy :clean_cached_query

	def self.common_relations(uris)
		commons = []
		server = RubySesame::Server.new("http://localhost:8080/openrdf-sesame")			
		repos = server.repository("skos")
		uris.each_with_index do |uri, i|
		  (i..10).each do |j|
				break if j > uris.length
		    query = %(
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT ?x ?label WHERE {
	?x skos:prefLabel ?label .
  ?x skos:related <http://datao.kb.nl/thesaurus/#{uri}> .
  ?x skos:related <http://datao.kb.nl/thesaurus/#{uris[j]}>
}
		    )
    		result = Hpricot.XML(repos.query(query, {:infer => false, :result_type => RubySesame::DATA_TYPES[:XML]}))
		    if (result/'//result').length > 0
    		  (result/'//result').each do |r|
						ppn = (r/'//uri').first.innerText.gsub("http://datao.kb.nl/thesaurus/", "")
						label = (r/'//literal').first.innerText.gsub("http://datao.kb.nl/thesaurus/", "")
        		commons << {:ppn => ppn, :label => label} unless uris.include?(ppn) || commons.map{|c| c[:ppn]}.include?(ppn)
		      end
		    end

        query = %(
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT ?x ?label WHERE {
  ?x skos:prefLabel ?label .
  <http://datao.kb.nl/thesaurus/#{uri}> skos:broader ?x .
  <http://datao.kb.nl/thesaurus/#{uris[j]}> skos:broader ?x .
}
        )
        result = Hpricot.XML(repos.query(query, {:infer => false, :result_type => RubySesame::DATA_TYPES[:XML]}))
        if (result/'//result').length > 0
          (result/'//result').each do |r|
            ppn = (r/'//uri').first.innerText.gsub("http://datao.kb.nl/thesaurus/", "")
            label = (r/'//literal').first.innerText.gsub("http://datao.kb.nl/thesaurus/", "")
            commons << {:ppn => ppn, :label => label} unless uris.include?(ppn) || commons.map{|c| c[:ppn]}.include?(ppn)
          end
        end

		  end
		  break if i == 10
		end
		return commons
	end

	def run
		if result_file.blank?
#			`ts-query -d skos '#{sparql_str}' | sed 1d > #{RAILS_ROOT}/public/cached_results/#{self.cached_query}.xml`
			server = RubySesame::Server.new("http://localhost:8080/openrdf-sesame")			
			repos = server.repository("skos")
#			raise sparql_str
			File.open("#{RAILS_ROOT}/public/cached_results/#{self.cached_query}.xml", "w") {|f| f.write(repos.query(sparql_str, {:infer => false, :result_type => RubySesame::DATA_TYPES[:XML]})) }

			self.result_file = "#{self.cached_query}.xml"
		end
	end


	def clean_cached_query
		File.unlink("#{RAILS_ROOT}/public/cached_results/#{self.result_file}") if File.exists?("#{RAILS_ROOT}/public/cached_results/#{self.result_file}")
	end
end

# simple_get_response.rb: attempt to extract events using NER software by URL
# Copyright (C) 2011 R. van der Ark, Koninklijke Bibliotheek - National Library of the Netherlands
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/ruby

require "rubygems"
require "json"
require "cgi"
require "src/simple_get_response"

class Array; def sum; inject( nil ) { |sum,x| sum ? sum+x : x }; end; end

VOCAB_URL = {
	"dbp" => %(http://tomcat1.kbresearch.nl/solr/dbpedia/select/?wt=json&rows=3&q=label_str:),
	"ggc" => %(http://tomcat1.kbresearch.nl/solr/ggc-thes-count/select/?wt=json&rows=3&q=prefLabel_str:)
}

ANALYZER_URLS = {
	"openNLP" => "http://localhost:8081/OpenNLP/",
	"naiveNE" => "http://localhost:5131/"
}

module Event
	def self.link_ranges(ranges)
		linked_ranges = []
		ranges.each do |range|
			terms = range.select{|k, v| k == :words}.flatten
			terms = terms[1..terms.length].map{|t| t.gsub(/[\(\),]+$/, "")}
			terms1 = []
			terms.each do |term|
				w = term.split(" ")
				terms1 << "#{w[1]}, #{w[0]}" if w.length == 2
			end
			terms = (terms + terms1).sort{|a,b| b.length <=> a.length}
			terms.each do |term|
				["dbp", "ggc"].each do |vocab|
					get = SimpleGetResponse.new("#{VOCAB_URL[vocab]}%22#{CGI.escape(term)}%22")
					if get.success?
						resp = JSON.parse(get.body)
						if resp["response"]["numFound"] > 0
							range[:link] ||= {}
							range[:link][vocab.to_sym] ||= []
							range[:link][vocab.to_sym] += resp["response"]["docs"].map{|d| d["id"]}
							linked_ranges << range
							break
						end
					end
				end
			end
		end
		return linked_ranges
	end

	def self.string_indexes(in_tokens, words)	
		string_indexes = []
		tokens = in_tokens.map{|t| t["token"]}
		tokens.each_with_index do |token, i|
			if token.downcase == words[0].downcase
				x = 0
				found = true
				words.each do |word|
					if tokens[i + x] 
						if tokens[i + x].downcase != word.downcase
							found = false
							break
						end
					else
						found = false
						break
					end
					x += 1
				end
				if found
					string_indexes << [i, i+x-1]
				end
			end
		end
		return string_indexes
	end

	def self.analyze(url, analyzer_url)
		ranges = []
		tokens = []
		sentence_lengths = []
		get = SimpleGetResponse.new("#{analyzer_url}?url=#{CGI::escape(url)}&format=json&mode=alto")
		if get.success?
			results = JSON.parse(get.body)
			results["sentences"].each_with_index do |sentence, index|
				sentence.each do |token|
					tokens << token
				end
				sentence_lengths << sentence.length
			end
			results["entities"].each_with_index do |entity, index|
				base_position = entity["sentence_index"] == 0 ? 0 : sentence_lengths[0..(entity["sentence_index"] - 1)].sum
				ranges << {
					:start_index => base_position + entity["start_index"],
					:end_index => base_position + entity["end_index"],
					:words => (entity["words"] ? entity["words"] : [entity["entity"]]),
					:type => entity["type"]
				}
			end
		end
		return [ranges, tokens]
	end

	def self.locate_transitive_event(event_words, analyzer, start = 0, rows = 5, url = nil)
		results = []
		event_words = event_words.split(" ")
		numfound = 0
		get = SimpleGetResponse.new(%(http://kbresearch.nl/solr/anp/select/?q=%22#{url || event_words.join("+")}%22&wt=json&start=#{start}&rows=#{rows}))
		if get.success?
			response = JSON.parse(get.body)
			numfound = response["response"]["numFound"]

			response["response"]["docs"].each do |doc|
				(ranges, tokens) = self.analyze(doc["id"] + ":alto", ANALYZER_URLS[analyzer])
				linked_ranges = link_ranges(ranges)
				event_indexes = string_indexes(tokens, event_words)

				ranges.each do |range|
					prox = []
					event_indexes.each do |event_index|
						prox << (range[:start_index] - event_index[1])
						prox << (event_index[0] - range[:end_index])
					end
					range[:proximity] = prox.reject{|p| p < 0}.sort.first	
				end
				results << {
					:id => doc["id"],
					:date => doc["date"][0], 
					:ranges => ranges,
					:tokens => tokens,
					:event_indexes => event_indexes
				}
			end
		end
		return [numfound, results]
	end
end

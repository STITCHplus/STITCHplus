#!/usr/bin/ruby
# classify.rb: Experimental text classifier using lucene weighted queries
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

require 'rubygems'
require 'json'
require 'simple_get_response'
require 'cgi'

# Extend Array class with step_with_index method
class Array
	def step_with_index n
		each_with_index do |element, index|
			yield(element, index) if index % n == 0
		end
	end
end

# Extract sum of Lucene's tf_idf scores combined with term frequency
def merge_tvs(term_vectors, c_freq)
	term_vectors.each do |tv|
		if c_freq[tv[:term]]
			c_freq[tv[:term]][:tf_idf_sum] += tv[:tf_idf]
			c_freq[tv[:term]][:freq] += 1
		else
			c_freq[tv[:term]] = {:freq => 1, :tf_idf_sum => tv[:tf_idf]}
		end
	end
	return c_freq
end

# Use the most relevant terms (best combo of tf_idf score and frequency) to formulate a new weighted lucene query
def build_query(winners, iteration)
	q = []
	(0..iteration).each do |i|
		((i+1)..(winners.length - 1)).each do |j|
			q << "(" + winners[i][0] + "^#{winners.length-i} AND " + winners[j][0] + "^#{(winners.length-j)/2})"
		end
	end
	return CGI::escape(q.join(" OR "))
end

# Load static tag data from json file (the proverbial 'training set')
# This is actually output from the tagall project in the deliverable (D2.7.12)
tag_data = JSON.parse(File.open("tag_data.json", "r") {|f| f.read})

# In 8 iterations, create a list of most relevant terms per tag based lucene's search results and weighted queries
(0..8).each do |iteration|
	klasses = tag_data.map{|t| t["od"]}.uniq
	klasses.each do |klass|
		cursor = tag_data.select{|t| t["od"] == klass} 
		puts klass + ": " + cursor.count.to_s + "\n----"
		collection_frequencies = {}
		cursor.each_with_index do |doc, index|
			collection_frequencies[doc["od"]] ||= {}
			get = SimpleGetResponse.new("http://tomcat.kbresearch.nl/solr/anp/select/?wt=json&start=0&rows=1&q=%22#{doc["url"]}%22&tv.all=true&qt=/tvrh")
			if get.success?
				resp = JSON.parse(get.body)
				tv_in = resp["termVectors"][1][3]
				term_vectors = []
				tv_in.step_with_index(2) do |term, index|
					term_vectors << {:term => term, :tf_idf => tv_in[index+1][5] } if tv_in[index+1][5] > 0.00001 && tv_in[index+1][5] < 0.01 && !(term =~ /^[0-9]+$/) && term.length > 4
				end
				collection_frequencies[doc["od"]] = merge_tvs(term_vectors, collection_frequencies[doc["od"]])
			end
		end

		collection_frequencies.each do |klass, term_vectors|
#			winners = term_vectors.select{|k,v| v[:freq] > 1 && v[:tf_idf_sum] / v[:freq] > 0.0001}.sort{|b,a| a[1][:freq] + a[1][:tf_idf_sum] / a[1][:freq] <=> b[1][:freq] + b[1][:tf_idf_sum] / b[1][:freq]}[0..15] 
			winners = term_vectors.select{|k,v| v[:freq] > 1}.sort{|b,a| (a[1][:tf_idf_sum]) * (a[1][:freq] * a[1][:freq]) <=> (b[1][:tf_idf_sum]) * (b[1][:freq] * b[1][:freq] )}[0..20] 
			winners.each do |term, scores|
				puts term + ": " + scores[:freq].to_s + " -- " + ('%5f' % (scores[:tf_idf_sum] / scores[:freq]))
			end
			exclude = tag_data.select{|t| t["od"] == klass}.map{|d| d["url"]}
			get = SimpleGetResponse.new("http://tomcat.kbresearch.nl/solr/anp/select/?wt=json&start=0&rows=100&q=%28#{build_query(winners, iteration)}%29&fl=id")
			if get.success?
				resp = JSON.parse(get.body)
				added = 0
				resp["response"]["docs"].map{|d| d["id"].sub("http://resolver.kb.nl/resolve?urn=","")}.each do |url|
					if exclude.include?(url)
						print "."
						STDOUT.flush
					else
						tag_data << {"od" => klass, "url" => url}
						added += 1
					end
					break if added == 50
				end
				puts
			end
		end
	end
end


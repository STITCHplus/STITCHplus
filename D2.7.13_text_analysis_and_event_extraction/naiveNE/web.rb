# web.rb: Takes a url, returns named entities as xml using naiveNE.rb
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

require 'sinatra'
require 'json'
require 'simple_get_response'
require 'naiveNE'

# Simple pass url as parameter; when using Alto xml, use mode=alto
get '/' do
	get = SimpleGetResponse.new(params[:url])
	if get.success?
		(ranges, tokens, alto_positions) = NaiveNE.analyze(get.body, params[:mode])
		if params[:format] == "json"
			content_type :json, 'charset' => "utf-8"
			retval = {}
			retval[:entities] = ranges.map do |range|
				{
					"type" => "misc", 
					"start_index" => range[:start_index], 
					"end_index" => range[:end_index] + 1, 
					"sentence_index" => 0,
					"entity" => range[:words].sort{|a,b| b.length <=> a.length}.first,
					"words" => range[:words].sort{|a,b| b.length <=> a.length}
				}
			end
			if params[:mode] == "alto" && alto_positions.length > 0
				retval[:sentences] = []
				retval[:sentences][0] = []
				tokens.each_with_index do |token, index|
					alto_pos = alto_positions[index]
					retval[:sentences][0] << {
						:token => token,
						:x => alto_pos[:x].to_i,
						:y => alto_pos[:y].to_i,
						:w => alto_pos[:w].to_i,
						:h => alto_pos[:h].to_i
					}
				end
			else
				retval[:sentences] = [tokens]
			end
			return JSON retval
		else
			content_type :xml, 'charset' => "utf-8"	
			entity_response = ranges.map{|r| "<misc startindex=\"#{r[:start_index]}\" endindex=\"#{r[:end_index]+1}\" sentenceindex=\"0\">#{r[:words].sort{|a,b| b.length <=> a.length}.first}</misc>"}.join("\n")
			token_response = ""
			tokens.each_with_index do |token, i| 
				token_response +="<token index=\"#{i}\""
				token_response += " x=\"#{alto_positions[i][:x]}\" y=\"#{alto_positions[i][:y]}\" w=\"#{alto_positions[i][:w]}\" h=\"#{alto_positions[i][:h]}\"" if alto_positions[i]
				token_response += ">#{token}</token>\n"
			end
			return "<naiveNEResponse><entities>#{entity_response}</entities><sentence index=\"0\">#{token_response}</sentence></naiveNEResponse>"
		end
	end
end

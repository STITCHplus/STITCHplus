# naiveNE.rb: Recognises named entities solely by looking at tokens starting with upcase 
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

require 'hpricot'

STOP_WORDS = ['de', 'en', 'van', 'ik', 'te', 'dat', 'die', 'in', 'een', 'hij', 'het', 'niet', 'zijn', 'is', 'was', 'op', 'aan', 'met', 'als', 'voor', 'had', 'er', 'maar', 'om', 'hem', 'dan', 'zou', 'of', 'wat', 'mijn', 'men', 'dit', 'zo', 'door', 'over', 'ze', 'zich', 'bij', 'ook', 'tot', 'je', 'mij', 'uit', 'der', 'daar', 'haar', 'naar', 'heb', 'hoe', 'heeft', 'hebben', 'deze', 'u', 'want', 'nog', 'zal', 'me', 'zij', 'nu', 'ge', 'geen', 'omdat', 'iets', 'worden', 'toch', 'al', 'waren', 'veel', 'meer', 'doen', 'toen', 'moet', 'ben', 'zonder', 'kan', 'hun', 'dus', 'alles', 'onder', 'ja', 'eens', 'hier', 'wie', 'werd', 'altijd', 'doch', 'wordt', 'wezen', 'kunnen', 'ons', 'zelf', 'tegen', 'na', 'reeds', 'wil', 'kon', 'niets', 'uw', 'iemand', 'geweest', 'andere', 'sinds', 'inhoud', 'datum', 'tijd', 'onderwerp', 'bron', 'red', 'volgens', 'enkele', 'dingen', 'week', 'boven', 'links', 'daaronder', 'rechts', 'eind']

module NaiveNE
	def self.analyze(txt, mode, numbers = false)
		text = txt.each_line.map{|l| l.gsub(/<[^>]+>/, "").gsub(/&[a-zA-Z]+;/, "")}
		tokens = []
		alto_positions = []
		if mode == "alto"
			doc = Hpricot.XML(txt)
			tokens = (doc/'//String').map{|node| node.attributes["CONTENT"]}
			alto_positions = (doc/'//String').map do |node| 
				{
					:x => node.attributes["HPOS"], 
					:y => node.attributes["VPOS"], 
					:w => node.attributes["WIDTH"], 
					:h => node.attributes["HEIGHT"]
				}
			end
		else
			text.each do |line| 
				parts = line.split(/[\s+\/\^]/)
				parts.each do |part|
					part.strip!
					s = part.scan(/[,.:;]+$/)
					if s.length > 0
						tokens << part.sub(s[0], "")
						tokens << s[0]
					elsif part =~ /^.+[^A-Z]+[A-Z].+$/
						x = part.scan(/^(.+[^A-Z]+)([A-Z])(.+)$/)
						tokens << x[0][0]
						tokens << x[0][2]
					else
						tokens << part
					end
				end
			end
		end
		ranges = []
		currange = []
		last_upper = false
		tokens.reject!{|t| t == "" }
		tokens.each_with_index do |token, i|
			is_upper = ((token[0..0] =~ /^[A-Z]$/) && token =~ /[a-zA-Z]/) || (numbers && token =~ /[0-9]+/)
			prev_period = i > 0 && token[i-1] == "."
			if token.length > 2 && is_upper && !prev_period
				currange << {token => i} unless STOP_WORDS.include?(token.downcase) || token =~ /^Rege/ || token =~ /rwerp$/ || token =~ /^Red/
			else
				if currange.length > 1
					(0..(currange.length-1)).each do |i|
						(i..(currange.length-1)).each do |j|
							ranges << currange[i..j]
						end
					end
				elsif currange.length == 1
					ranges << currange
				end
				currange = []
			end
			last_upper = is_upper
		end

		merged_ranges = []
		ranges.each do |range|
			join_into = nil
			merged_ranges.each_with_index do |mrange, index|
				mrange.each do |r|
					indexes = r.map{|rr| rr.map{|k,v| v}}.flatten
					range.each do |inrange|
						rindex = inrange.map{|k,v| v}.first
						if indexes.include?(rindex)
							join_into = index
							break
						end
					end
				end
			end
			if join_into
				merged_ranges[join_into] << range
			else
				merged_ranges << [range]
			end	
		end

		cleaned_ranges = []
		merged_ranges.each_with_index do |range, i|
			indexes = range.map{|r| r.map{|rr| rr.map{|k,v| v}}}.flatten.uniq.sort
			words = range.map{|r| r.map{|rr| rr.map{|k,v| k }}.join(" ")}.flatten
			cleaned_range = {:start_index => indexes.first, :end_index => indexes.last, :words => words}
			cleaned_ranges << cleaned_range
		end
		return [cleaned_ranges, tokens, alto_positions]
	end
end

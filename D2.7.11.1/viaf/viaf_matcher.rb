#    ViafMatcher module: Uses the open search endpoint of VIAF to match a person's metadata
#    Copyright (C) 2011  R. van der Ark
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "cgi"
require "rubygems"

# Requires the hpricot gem to parse XML
# https://github.com/whymirror/hpricot
require "hpricot"
require "simple_get_response"
require "person_matcher"

# Uses the open search endpoint of VIAF to match a person's metadata
module ViafMatcher
	# Takes an array of strings for labels, optionally year of birth (int) and year of death (int)
	# Returns the scores for a set of labels
	# as an array of hashes in the form:
	#  - h[:score] (int): the score of the match
	#  - h[:label] (string): the VIAF label for the person (preferred, or alternative)
	#  - h[:uri] (string): the VIAF linked data URI for the person's metadata
	def ViafMatcher.scores(labels, birth_date, death_date, verbose = true, delay = 3)
		# Create a weighted person matcher object
		# Max score for label: 56
		# Max score for years: 44
		person_matcher = PersonMatcher.new(56, 22)

		# Array which keeps track of all the VIAF linked data uris which have already been checked
		uris_checked = []

		# Stores the score hashes
		scores = []

		# Loop through all the labels
		labels.each do |label|
			puts "(FIND) #{label} (#{birth_date}-#{death_date})\n----" if verbose
			# Use optional delay, VIAF open search will choke on too many requests per day
			sleep delay

			# Do a GET request to VIAF, searching for the current label
			resp = SimpleGetResponse.new(%(http://viaf.org/viaf/search?query=local.names+all+%22#{CGI::escape(label)}%22&sortKeys=holdingscount&maximumRecords=100&httpAccept=application/rss%2bxml))
			if resp.success?
				# Parse the open search response
				xml = Hpricot.XML(resp.body)
				# Generate an array of links to linked data uris from the response using xpath
				links = (xml/'//item/link')
				if links.length > 0
					# Take only the first hit of the search response as the current uri to check labels against
					# TODO: for thorough checking all the search results should of course be checked, but
					# this takes an enormous amount of time, given the delays
					uri = links[0].innerText

					# Checked whether this uri has already been scored
					unless uris_checked.include?(uri)
						# Introduce another delay to prevent choking
						sleep delay
						# Do a GET request to the current linked data uri
						resp = SimpleGetResponse.new("#{uri}.rdf")
						if resp.success?
							# Parse the response
							rdf = Hpricot.XML(resp.body)
							# Use xpath to determine all the preferred labels and altlabels in the response
							prefLabels = (rdf/'//rdaGr2:preferredNameForThePerson')
							altLabels = (rdf/'//rdaGr2:variantNameForThePerson')
							# Use xpath to retrieve VIAF's authority date of birth and date of death
							birth_dates = (rdf/'//rdaGr2:dateOfBirth')
							viaf_birth_date = birth_dates[0].innerText.to_i if birth_dates.length > 0
							death_dates = (rdf/'//rdaGr2:dateOfDeath')
							viaf_death_date = death_dates[0].innerText.to_i if death_dates.length > 0
							# Concatinate all the preferred and alternative labels to one list
							viaf_labels = (prefLabels || []) + (altLabels || [])
							# Remove some redundant information from the VIAF labels and remove remaining doubles
							viaf_labels = viaf_labels.map {|lbl| lbl.innerText.gsub(/,([^a-zA-Z]| or | suora )+$/, "").gsub(/\d{4}\-?\d{4}?/, "").gsub(/\(.+\)/, "").gsub(". ", ".") }.uniq
							# Loop through all the local labels 
							labels.each do |lbl1|
								# Generate the scores mapping the viaf metadata against the local metadata
								cur_scores = viaf_labels.map do |lbl|
									# Calculate the score between the local metadata and the viaf metadata
									score = person_matcher.calculate_match({
											:lbl => lbl, 
											:dod => viaf_death_date,
											:dob => viaf_birth_date
										}, {
											:lbl => lbl1,
											:dob => birth_date, 
											:dod => death_date
										}
									)
									{:score => score, :label => lbl, :uri => uri}
								end
								# append to the complete scores array
								scores += cur_scores
							end
						end
						# Sort the scores
						scores = scores.sort{|a,b| b[:score] <=> a[:score]}						
						puts "(VIAF) #{scores[0][:label]} (#{viaf_birth_date}-#{viaf_death_date}) scores #{scores[0][:score]} at URI: #{uri}" if verbose && scores.length > 0
						# Add the current VIAF linked data uri to the uris checked list
						uris_checked << uri
					end
				end
			end
		end
		# return the scores
		return scores
	end
end

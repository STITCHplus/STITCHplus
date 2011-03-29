#    PersonMatcher class: weighted matcher for label and year of birth/death between two persons
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

# Makes use of the amatch gem for the Levenshtein algorithm:
# http://flori.github.com/amatch/ 
require "rubygems"
require "amatch"

# Class to create a weighted match between two persons based on:
# - label
# - date of birth
# - date of death
class PersonMatcher
	# Accessors for the weight applied for years and the weight applied for labels 
	attr_accessor :lbl_wt, :yr_wt

	# Initialize, optionally set the weight for label and years.
	def initialize(weight_for_label = 50, weight_for_year = 25)
		self.lbl_wt = weight_for_label
		self.yr_wt = weight_for_year
	end

	private
	# Use the Levenshtein algorithm to calcluate the edit distance between two strings
	def edit_distance(a, b)
		m = Amatch::Levenshtein.new(a)
		return m.match(b)
	end

	# Return the difference between two years.
	# If the allow_penalty flag is set the difference between years may exceed the weight set for years
	# returning a negative score. Else the minimum score becomes 0
	def compare_years(a, b, allow_penalty = true)
		return (self.yr_wt - (a - b).abs) < -(self.yr_wt) ? (allow_penalty ? -(self.yr_wt) : 0) : self.yr_wt - (a - b).abs if a && b
		return 0
	end

	public
	# Calculate a weighted match between two persons
	# Takes two hashes in the form:
	#  h[:dob] (int): year of birth
	#  h[:dod] (int): year of death
	#  h[:lbl] (string): name label
	def calculate_match(a, b)
		# Calculate the edit distance for the two name labels
		label_score = self.lbl_wt - edit_distance(a[:lbl], b[:lbl])

		# Calculate the difference in years for date of birth, 
		# use a penalty only if the edit-distance more than 0
		year1 = compare_years(a[:dob], b[:dob], !(label_score == self.lbl_wt))

		# In some cases date of birth and date of death were swapped:
		# We consider it a match anyway, if:
		#  - year of birth for A is equal to year birth for B
		#  - both values are not nil
		#	 - one of the values IS nil
		year1 = self.yr_wt if a[:dob] == b[:dod] && [a[:dob], b[:dob]].include?(nil) && !(a[:dob] == nil && b[:dod] == nil)
		# Calculate the difference in years for date of death
		year2 = compare_years(a[:dod], b[:dod], !(label_score == self.lbl_wt))
		# Reverse case of above example
		year2 = self.yr_wt if a[:dod] == b[:dob] && [a[:dod], b[:dod]].include?(nil) && !(a[:dod] == nil && b[:dob] == nil)

		# Return the weighted score
		return label_score + year1 + year2
	end
end

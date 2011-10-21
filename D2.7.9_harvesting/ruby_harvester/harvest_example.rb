#!/usr/bin/ruby

#    Harvester class: Extensible OAI harvester base class using the GetRecords retrieval method.
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

require "fileutils"
require "harvester"
require "mysql"

class SKOSHarvester < Harvester
	attr_accessor :connection

	# Create/update records
	def store_records(record_xml, identifiers)
		puts record_xml
	end

	# Delete records
	def delete_records(records)
		puts records.inspect
	end
end

harvester = SKOSHarvester.new("http://kbresearch.nl/general/thesaurus_harvest/?verb=ListRecords&set=GGC-THES&metadataPrefix=dcx", {:from_date => "2010-06-01"} )
harvester.run 

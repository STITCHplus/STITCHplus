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

require "net/http"
require "uri"
require "rubygems"
require "hpricot"
require "date"
require "tempfile"

# Extensible OAI harvester base class using the GetRecords retrieval method.
class Harvester
	attr_accessor :resumption_token, :from_date, :url, :infile

	# Initialize new harvester (optionally with custom resumption token and from date)
	def initialize(set_url, options = {})
		# Set the OAI base url and params
		self.url = set_url
		# Use the resumption token from the options
		self.resumption_token = options[:resumption_token] if options[:resumption_token]
		# Use from date from the options
		self.from_date = options[:from_date] if options[:from_date]

		# Create file for resumption token, unless it already exists
		FileUtils.touch "resumption_token" unless File.exists?("resumption_token")
		# Create a log file to keep track of the resumption tokens
		FileUtils.touch "resumption_tokens.log" unless File.exists?("resumption_tokens.log")
		# Create a file which stores the date of this harvest
		FileUtils.touch "latest_harvest" unless File.exists?("latest_harvest")

		# If no resumption token was given in the options use the resumption token from the file
		if resumption_token.nil?
			File.open("resumption_token", "r") {|f| self.resumption_token = f.read }
			self.resumption_token.chomp!
			self.resumption_token = "start" if self.resumption_token == ""
		end

		# If no from date was given, use the from date from the file (blank is allowed)
		if from_date.nil?
			  File.open("latest_harvest", "r") {|f| self.from_date = f.read }
			  self.from_date.chomp!
			  File.open("latest_harvest", "w") {|f| f.write Date.today.strftime("%Y-%m-%d") }
		end
	end

	# Run the harvest
	def run
		# Run as long as the resumption token is not blank
		while(!(resumption_token =~ /^\s*$/))
			# Create a temp file for the OAI response
			self.infile = Tempfile.new(resumption_token.gsub(/[\-\!:]/, "_"))

			# Write the OAI response to temp file
			infile.write(resumption_token == "start" ?
				Net::HTTP.get_response(URI.parse("#{url}#{from_date == "" ? "" : "&from=#{from_date}"}")).body :
				Net::HTTP.get_response(URI.parse("#{url}&resumptionToken=#{resumption_token}")).body
			)
			infile.flush

			# Parse the OAI response wrapper with  Hpricot
			response = get_oai_wrapper

			# If there was a valid response, handle storage of xml, else skip the response, continue with the next
			if(response)
				# Terminate in case of response error
				raise_error response_error_for(response) if response.at("/OAI-PMH/error")

				# Save the resumption token from the response
				save_resumption_token(response)

				# Handle response
				store_response
			else
				resumption_token_from_faulty_xml
			end
		end
	end


	protected
		# Override this method to store the parsed xml in 'records' in any way you please
		def store_records(record_xml, identifiers)
			puts "Harvester.store_records, override this method to store the records in record_xml, having identifiers: #{identifiers.inspect}"
		end

		# Override this method to remove the records with identifier listed in the 'records' array
		def delete_records(records)
			puts "Harvester.delete_records, override this method to delete records in Array: #{records.inspect}"
		end

	private
		# Store the response
		def store_response			
			# Retrieve all the deleted record identifiers from the response, parse with Hpricot
			deleted_records = deleted_records_from_response
			# Retrieve all the records to be created/updated
			(record_xml, identifiers) = records_from_response

			# Delete all the deleted records
			delete_records(deleted_records)
			# Create/update the other records
			store_records(record_xml, identifiers)
		end

		# Run xslt to filter out the xml for all the deleted records from the response
		def deleted_records_from_response
			deleted_xml = `xsltproc xsl/deleted_records.xsl #{infile.path}`
			parsed_xml = Hpricot.XML(deleted_xml)
			return (parsed_xml/'ListRecords/identifier').map{|identifier| identifier.innerText }
		end

		# Run xslt to filter out the xml for all the records to be updated/created in the response
		def records_from_response
			xml = `xsltproc xsl/get_records.xsl #{infile.path}`
			identifier_xml = `xsltproc xsl/get_record_identifiers.xsl #{infile.path}`
			parsed_identifiers = Hpricot.XML(identifier_xml)
			identifiers = (parsed_identifiers/'/ListRecords/identifier').map{|i| i.innerText}
			return [xml, identifiers]
		end

		# Retrieve header information from the oai wrapper, raise warning if the xml cannot be parsed by xslt
		def get_oai_wrapper
			wrapper_xml = `xsltproc xsl/get_wrapper.xsl #{infile.path} 2> err/xsl_err.out`
			if File.size?("err/xsl_err.out")
				FileUtils.cp(infile.path, "xmlfaulty/#{resumption_token.gsub(/[\-\!:]/, "_")}.xml")
				raise_warning "Faulty XML encountered at resumption token: #{resumption_token}"
				return nil
			end
			Hpricot.XML(wrapper_xml)
		end

		# Raise an error message + the entire response body
		def raise_error(str)
			raise "#{str}\nRESPONSE BODY:\n#{dump_response}"
		end	

		# Print a warning to stderr
		def raise_warning(str)
			$stderr.puts str
		end

		# Return he entire response string
		def dump_response
			File.open(infile.path) {|f| f.read }
		end
	
		# Retrieve the OAI error message
		def response_error_for(response)
			"OAI response error code: #{response.at("/OAI-PMH/error").attributes["code"]}" 
		end

		# Save the resumption token for this iteration in a file, append it to the resumption token log
		def save_resumption_token(response)
		  # Get the resumption token from the parsed OAI response
			if response.at("/OAI-PMH/ListRecords/resumptionToken")
			  self.resumption_token = response.at("/OAI-PMH/ListRecords/resumptionToken").innerText
			else
				self.resumption_token = ""
			end

		  # Save the resumption token in a file
		  File.open("resumption_token", "w") {|f| f.write(resumption_token) }
			File.open("resumption_tokens.log", "a") {|f| f.write(resumption_token + "\n") }
			puts "Resumption token saved successfully: #{resumption_token}"
		end
				
		def resumption_token_from_faulty_xml
		  doc = File.open(self.infile.path) { |f| f.read }
			response = Hpricot.XML(doc)
			raise response.inspect
		end
end

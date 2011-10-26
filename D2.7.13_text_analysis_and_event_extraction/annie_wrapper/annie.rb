# annie.rb: Wrapper service for Annie named entity analyzer
# For details see: http://opendatachallenge.kbresearch.nl/
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


require 'cgi'
require 'rubygems'
require 'erb'
require 'sinatra'
require 'hpricot'
require 'src/simple_get_response'


get('/') do 
	content_type :xml, 'charset' => "utf-8"
	url = CGI.escape(params["url"])
	
	get = SimpleGetResponse.new("http://services.gate.ac.uk/annie/annie.jsp?url=#{url}&annotation[]=Person&annotation[]=Location&annotation[]=Organization")
	if get.success?
		doc = Hpricot.XML(get.body)
		response = "<annieResponse><entities>"
		response += (doc/'//Person').map{|elem| "<person>#{elem.innerText.gsub("&", "&amp;")}</person>"}.join("\n") + "\n";
		response += (doc/'//Location').map{|elem| "<location>#{elem.innerText.gsub("&", "&amp;")}</location>"}.join("\n") + "\n";
		response += (doc/'//Organization').map{|elem| "<organization>#{elem.innerText.gsub("&", "&amp;")}</organization>"}.join("\n") + "\n";
		response += "</entities></annieResponse>"
	else
		response = "<remoteError>#{get.response.code}</remoteError>"
	end
	return response
end

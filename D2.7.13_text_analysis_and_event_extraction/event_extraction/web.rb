# web.rb: Some tools exploring possibilities for event extraction
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

require 'erb'
require 'mongo'
require 'sinatra'
require 'json'
require 'event'
require 'cgi'
require 'src/simple_get_response'

get '/event' do
	(@numfound, @results) = Event::locate_transitive_event(params[:event_words], params[:analyzer] || "naiveNe", params[:start], params[:rows])
	if params[:format] == "html"
		erb :event
	elsif params[:format] == "map"
		@results = JSON @results.sort{|a, b| a[:date] <=> b[:date]}
		erb :map
	else
		content_type :json, 'charset' => "utf-8"
		return JSON @results
	end
end

get '/visual/' do
	(numfound, results) = Event::locate_transitive_event(params[:event_words], params[:analyzer] || "naiveNE", 0, 1, params[:url])
	@view = JSON results[0]
	erb :visual
end

get '/lat_long/' do
	get = SimpleGetResponse.new("http://data.kbresearch.nl/#{CGI::escape(params[:identifier])}?lat+long")
	if get.success?
		x = JSON.parse(get.body)
		latlong =  x.select{|k,v| k == "lat" || k == "long"}.map{|x| x[1]}
		return JSON latlong
	else
		return "null"
	end
end

get '/fast_map/:identifier' do
	connection = Mongo::Connection.new("kbresearch.nl", 27017)
	collection = connection.db("expand_test")["historical_events"]
	@events = JSON collection.find({"type" => params[:identifier]}, {:sort => ["date", Mongo::DESCENDING]}).to_a
	erb :fast_map
end

get '/data/:identifier' do
	get = SimpleGetResponse.new("http://data.kbresearch.nl/#{params[:identifier]}?#{params.reject{|k, v| k == "identifier"}.map{|k,v| k.gsub(" ", "+")}.join("+")}")
	return get.body if get.success?
	return "null"
end

get '/' do
	erb :index
end

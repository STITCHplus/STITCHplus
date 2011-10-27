#    tagall.rb: Tool to link concepts from controlled vocabularies to full records
#    For details see: http://opendatachallenge.kbresearch.nl/
#    Copyright (C) 2011  R. van der Ark, Koninklijke Bibliotheek - National Library of the Netherlands
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

# Dependencies
# Sinatra, a small RESTful web framework using mongrel server or thin
require 'sinatra'
require 'cgi'
require 'json'
require 'src/finder'

# Convert given URL to namespaced URI based on configuration
# Example:
# url2uri("http://foo.bar/baz/123", {"Foo:Bar:Baz" => "http://foo.bar/baz/", "X:Y" => "http://x.y/"}) returns:
# Foo:Bar:Baz:123
def url2uri(url, conf)
	conf["namespaces"].each{|k, v| url.sub!(v, "#{k}:")}
	return url
end

def uri2url(uri, conf)
	conf["namespaces"].each{|k, v| uri.sub!("#{k}:", v)}
	return uri
end

def uri2info_url(uri, conf)
	conf["info_namespaces"].each{|k, v| uri.sub!("#{k}:", v[0])}
	return uri
end

# START sinatra REST server settings

# Global settings at boot time
# Set the location of the (JSON) configuration file
config_file = "config/config.json"

# Parse the configuration and store in global variable conf
conf = JSON.parse(File.open(config_file) {|f| f.read})

# Instantiate finder with loaded configuration
finder = Finder.new(conf)

# Set the public directory as public web root for static files: js, img, css
set :public, File.dirname(__FILE__) + "/public"

get '/add_link' do
	content_type "text/javascript", 'charset' => "utf-8"
	new_params = params.reject{|k,v| k == "callback"}
 	get = SimpleGetResponse.new("#{conf["od_storage"]["add"]}?" + new_params.map{|k,v| "#{k}=#{CGI.escape(v)}"}.join("&")) 
	if get.success?
		if params[:callback]
			return "#{params[:callback]}(#{JSON new_params});"
		else
			return JSON new_params
		end
	else
		return "{}"
	end
end

get '/delete_link' do
	content_type "text/javascript", 'charset' => "utf-8"
  new_params = params.reject{|k,v| k == "callback"}
  get = SimpleGetResponse.new("#{conf["od_storage"]["delete"]}?" + new_params.map{|k,v| "#{k}=#{CGI.escape(v)}"}.join("&"))
  if get.success?
    if params[:callback]
      return "#{params[:callback]}(#{JSON new_params});"
    else
      return JSON new_params
    end
  else
    return "{}"
  end
end

get '/retrieve_links' do
	content_type "text/javascript", 'charset' => "utf-8"
	get = SimpleGetResponse.new("#{conf["od_storage"]["retrieve"]}?url=#{params[:id] || params[:url]}")
	if get.success?
		if params[:callback]
			return "#{params[:callback]}(#{get.body});"
		else
			return get.body
		end
	else
		return "{}"
	end
end

# Listener (GET, application/json) for searches
# Use URL parameters as options for search; example:
# http://domain/find_by_params?namespace=GGC-THES%3AAC&domain=personParam&start=1&limit=5&query=Albert+Einstein
# Gives the search results as a JSON response
get '/find_by_params' do
	content_type "text/javascript", 'charset' => "utf-8"
	if params[:callback]
		return "#{params[:callback]}(#{JSON finder.find_in(params)});"
	else
		return JSON finder.find_in(params)
	end
end

# Listener (GET, application/json) providing information on a specific concept from a namespaced controlled vocabulary; example
# http://domain/info/GGC-THES:DBP:Albert_Einstein
# Gives the concept information as a JSON response
get '/info/:identifier' do
	content_type "text/javascript", 'charset' => "utf-8"
	params[:identifier].sub!("_SLASH_", "/")
	ns = url2uri(params[:identifier], conf).sub(/:[^:]+$/, "")
	url = uri2info_url(params[:identifier], conf)
	if params[:callback]
		return "#{params[:callback]}(#{finder.info(url, ns, conf["info_namespaces"][ns][1])});"
	else
		return finder.info(url, ns, conf["info_namespaces"][ns][1])
	end
end

get '/show_info' do
  content_type "text/javascript", 'charset' => "utf-8"
  params[:od].sub!("_SLASH_", "/")
  ns = url2uri(params[:od], conf).sub(/:[^:]+$/, "")
  url = uri2info_url(params[:od], conf)
  if params[:callback]
    return "#{params[:callback]}(#{finder.info(url, ns, conf["info_namespaces"][ns][1])});"
  else
    return finder.info(url, ns, conf["info_namespaces"][ns][1])
  end
end

# Listener (GET) for main index action using URL parameters; Example:
# http://www.kbresearch.nl/general/ugc/?id=http%3A%2F%2Fresolver.kb.nl%2Fresolve%3Furn%3Danp%3A1957%3A09%3A21%3A8%3Ampeg21&url=http%3A%2F%2Fresolver.kb.nl%2Fresolve%3Furn%3Danp%3A1957%3A09%3A21%3A8%3Ampeg21
# Renders the index action in 'views/index.erb'
get '/' do
	content_type "text/javascript", 'charset' => "utf-8"
	@base_url = "http://" + request.host_with_port #"http://kbresearch.nl/general/tagall_jsonp" 
	@namespaces = JSON conf["namespaces"]
	@domain_names = JSON conf["domain_names"]
	@search_domains = JSON conf["search_domains"]
	@identifier = params[:id] || params[:url]
	@domains = JSON conf["domains"]
	@container = params[:container]
	erb :jsonp
end

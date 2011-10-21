#    finder.rb: Class for dispatching dynamically created queries to several search endpoints 
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


require 'src/simple_get_response'
require 'rexml/document'
require 'xml/xslt'


# Class for dispatching dynamically created queries to several search endpoints
# See json files in config directory for examples.
class Finder
  attr_accessor :namespaces, :search, :pretty_name, :stylesheet_portal, :linked_data_url

  # Constructor
  # Configures the Finder object with configuration for distributing searches
  # See json files in config directory for examples
  # linked_data_url: url that provides information about a concept from a given vocabulary (see info method)
  # namespaces: hash mapping namespaces to linked data urls for vocabularies
  # search: hash containing configuration for the search endpoints
  # stylesheet_portal: refers to a portal that receives:
  #   - a search response in XML via URL
  #   - a XSL stylesheet to transform (normalize) the search response to JSON via URL
  def initialize(conf)
    self.linked_data_url = conf["linked_data_url"]
    self.namespaces = conf["namespaces"]
    self.search = conf["search"]
    self.pretty_name = conf["prettyNames"]
    self.stylesheet_portal = conf["stylesheet_portal"]
  end

  # Dispatch a search to the chosen endpoint
  # Receives options hash as follows:
  # {
  #   :namespace => the namespace for the search endpoint,
  #   :start => start index of the search (minimum = 1),
  #   :limit => number of search results,
  #   :domain => the concept 'domain' to search in ["personParam"|"placeParam"|"orgParam"],
  #   :query => the string searched for (like: "Albert Einstein")
  # }
  def find_in(options)
    # Retrieve the search options for the given namespaces
    opts = self.search[options[:namespace]]
    # Start building the URL for the search endpoint, using the base URL
    url = opts["baseUrl"]
    # Create the query parameter of the search URL
    query = "#{opts["queryParam"]}#{CGI::escape(options[:query].gsub(/\s+/, opts["queryConcat"]))}"
    # Create the start-index parameter of the search URL
    start = options[:start] && opts["startParam"] ? "#{opts["startParam"]}=#{options[:start].to_i + opts["start_correction"]}" : nil
    # Create the limit parameter of the search URL
    limit = options[:limit] && opts["maxParam"] ? "#{opts["maxParam"]}=#{options[:limit]}" : nil
    # Create the 'domain' parameter of the search URL (persons, places, or organisation)
    domain = opts[options[:domain]]
    # Build the complete search URL
    url = "#{url}&#{[start, limit, query + domain].reject{|v| v.nil?}.join("&")}"

    get = SimpleGetResponse.new(url)
    if get.success?
      json_body = xsltconvert(get.body, File.read(opts["stylesheet"]))
      # Parse the response body from JSON if the GET request was succesful
      result_set = JSON.parse(json_body)
      # If the result set was not instantiated above, create an empty Hash
      result_set ||= {}
      # Append request information to the result set Hash
      result_set["domain"] = options[:domain]
      result_set["namespace"] = options[:namespace]
      result_set["pretty_name"] = self.pretty_name[options[:namespace]]
      # Return the result set
      return result_set
    else
      return {"domain" => options[:domain], "namespace" => options[:namespace], "pretty_name" => self.pretty_name[options[:namespace]]}
    end
  end

  # Get information on a concept in a controlled vocabulary from the linked data URL
  # using a namespaced URI; convert it to JSON using xslt
  def info(url, ns, suffix)
    get = SimpleGetResponse.new(url + suffix)
    if get.success?
      return xsltconvert(get.body, File.read(self.search[ns]["info_stylesheet"])).gsub("\n", " ") rescue "{label: {}, properties: {}}"
    end
    # If the GET request was unsuccessful, return empty information as JSON
    return "{label: {}, properties: {}}"
  end

  private
  def xsltconvert(xml, xsl)
    parser = XML::XSLT.new
    parser.xml = REXML::Document.new(xml)
    parser.xsl = REXML::Document.new(xsl)
    parser.serve
  end
end
        

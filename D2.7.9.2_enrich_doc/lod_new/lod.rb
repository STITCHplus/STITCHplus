#    lod.rb: Sinatra service to retrieve linked data from mongodb for thesaurus entries 
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


require 'rubygems'
require 'erb'
require 'mongo'
require 'sinatra'
require 'json'
require 'hpricot'
require 'rexml/document'
require 'src/simple_get_response'

mime_type :json, 'application/json'

def get_record(id)
	ns = {
		"GGC-THES:VIAF:" => "http://viaf.org/viaf/",
		"GGC-THES:DBP:" => "http://dbpedia.org/resource/",
		"GGC-THES:DNB:" => "http://d-nb.info/gnd/"
	}
	coll = Mongo::Connection.new("kbresearch.nl", 27017).db("expand_test")["ggc_thes"]
	cursor = nil

	if id =~ /GGC\-THES:AC:/ || id =~ /^\d{8}[X\d]$/
		cursor = coll.find("id" => id.sub("GGC-THES:AC:", ""))
	else
		ns.each{|k, v| id.sub!(k, v)}
		cursor = coll.find("sameAs" => id)
		cursor = coll.find("id" => {"$in" => cursor.to_a.map{|d| d["id"]}})
		
	end

	if(cursor)
		return_doc = {"sameAs" => {}}
		cursor.each do |doc|
			return_doc["id"] = doc["id"]
			namespace = ""
			ns.each do |namesp, url|
				namespace = namesp.sub(/:$/, "") if doc["sameAs"] =~ /#{url}/
			end
			return_doc["sameAs"][namespace] ||= []
			return_doc["sameAs"][namespace] << {"id" => doc["sameAs"], "score" => doc["score"]}
			return_doc["prefLabel"] = doc["prefLabel"] if doc["prefLabel"]
		end
		return nil if return_doc["sameAs"] == {}
		return return_doc
	else
		return nil
	end
end

def render_json(doc)
	content_type :json, 'charset' => "utf-8"
	return JSON doc if doc 
	return "null"
end

def rdf_open
	%(<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:srw="http://www.loc.gov/zing/srw/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:skos="http://www.w3.org/2004/02/skos/core#">)
end

def rdf_close
	"</rdf:RDF>"
end

def render_rdf(doc, limit)
	content_type :xml, 'charset' => "utf-8"
	return rdf_open + rdf_close unless doc

	preflabels = (doc["prefLabel"] || []).map do |lang, lbl|
		m = lbl.scan /(\\u([0-9A-F]{4}))/
		m.each {|m| lbl.gsub!(m[0], "&#x#{m[1]};")}
		lbl = REXML::Text::unnormalize(lbl) 
		[lang, lbl]
	end

	response = %(#{rdf_open}<skos:Concept rdf:about="http://datao.kb.nl/thesaurus/#{doc["id"]}">)
	preflabels.each {|lang, lbl|response += %(<skos:prefLabel xml:lang="#{lang}">#{lbl}</skos:prefLabel>)}
	doc["sameAs"].each do |k, links| 
		links.sort{|a, b| (b["score"] ? b["score"] : 0) <=> (a["score"] ? a["score"] : 0)}.each_with_index do |k, i|
			break if i == limit
			response +=  %(<skos:related rdf:resource="#{k["id"]}" />)
		end
	end
	response += %(</skos:Concept></rdf:RDF>)
end

def render_html(doc, limit)
	content_type :html, 'charset' => "utf-8"
	@doc = doc
	@limit = limit
	erb :show
end

def show(id, format, limit)
	limit = limit.to_i if limit
	limit ||= 1
	if format == "rdf" || format == "xml"
		render_rdf(get_record(id), limit)
	elsif format == "html"
		render_html(get_record(id), limit)
	else
		render_json(get_record(id))
	end
end

get('/get/:id.*') { show(params[:id], params[:splat][0], params[:limit]) }
get('/get/:id') { show(params[:id], params[:format], params[:limit]) }

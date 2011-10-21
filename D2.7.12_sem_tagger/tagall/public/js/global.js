/*
#    global.js: Global scope javascript for tagall 
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
*/

var showing_results = false;
var last_query = null;
var links = [];
var finders = [];
var search_domains;
var namespaces;
var identifier;
var DOMAIN_NAMES;
var disclaimers = {
    "GEO": "All locations are retrieved from <a target='_blank' href='http://www.geonames.org/'>Geonames</a>.",
    "DBP": "All miscelaneous terms are retrieved from <a target='_blank' href='http://dbpedia.org/'>DBPedia</a>.",
    "VIAF": "All personal names are retrieved from <a target='_blank' href='http://viaf.org/'>Virtual Authority File</a> (OCLC)."
};

function add_link(params) {
	// url=x&label=y&od=z
	for(var ns in namespaces) 
		params["uri"] = params["uri"].replace(namespaces[ns], ns + ":");
	
	var storeParams = {
		"url": params["identifier"],
		"label": params["label"],
		"od": params["uri"]
	};
	new Ajax.Request("/database/store.py?" + Object.toQueryString(storeParams), {
		method: "get",
		onSuccess: function(r) {
			var link = new Link(params.label, params.uri);
			link.render();
			links.push(link);
		}
	});
}

function load_links(json_links) {
	links = [];
	for(var x in json_links) 
		links.push(new Link(json_links[x].label, x));	
}

function load_finders(domains) {
	search_domains.each(function(ns) {
		domains[ns].each(function(domain) {
			finders.push(new Finder(ns, domain));
		});
	});
}

function get_info(uri) {
	$('info_block').show();
	$('info_spinner').show();
	$('info_header').hide();
	$('info_add').hide();
	$('info_flags').hide();
	$('info_properties').hide();
	$('search_results').hide();
	$('search_result_tabs').hide();
	for(ns in namespaces)
		uri = uri.replace(namespaces[ns], ns + ":");
	new Ajax.Request("info/" + uri.replace("/", ""), {
		"method": "get",
		"onSuccess": function(r) {
			render_info(r.responseText.evalJSON(), uri);
		}
	}); 
}
function render_info(info, uri) {
	var labelEmpty, propEmpty;
	$('info_spinner').hide();
	if(!(labelEmpty = isEmpty(info.label))) {
		$('info_header').innerHTML = "";
		$('info_flags').innerHTML = "";
		$('info_properties').innerHTML = "";
		$('info_add').innerHTML = "";
		if(info.thumbnail) 
			$('info_properties').insert(new Element("img", {"src": info.thumbnail, "style": "width: 80px; float: right"}));

		["en", "ja", "fr", "zh", "de", "ru", "nl", "il", "ar"].each(function(lang) {
			if(info.label && info.label[lang]) {
				var langLabel = new Element("div", {"id": "info_label_" + lang, "class": "info_label"});
				var langLink = new Element("a");
				var langImg = new Element("img", {"src": "img/flags/" + lang + ".png"});
				langLabel.insert(info.label[lang]);
				$('info_header').insert(langLabel);
				langLabel.hide();

				langLink.insert(langImg);
				$('info_flags').insert(langLink);
				langLink.observe("mouseover", function(e) {
					$$('.info_label').each(Element.hide);
					$('info_label_' + lang).show();
				});
			}
			if($('info_label_en'))
				$('info_label_en').show();
			else if($$('.info_label').length > 0)
				$$('.info_label')[0].show()
		});
		$('info_header').show();
		$('info_flags').show();
		var addLink = new Element("a");
		addLink.insert("Add this tag");	
		$('info_add').insert(addLink);
		$('info_add').show();
		addLink.observe("click", function(e) {
			if(confirm("Are you sure you want to add this tag?")) {
				add_link({
					"identifier": identifier,
					"uri": uri,
					"label": (info.label["en"] ? info.label["en"] : info.properties["name"])
				});
			}
		});
	}

	if(!(propEmpty = isEmpty(info.properties))) {
		var defList = new Element("dl");
		for(prop in info.properties) {
			var dt = new Element("dt");
			var dd = new Element("dd");
			dt.insert(prop);
			dd.insert(info.properties[prop]);
			defList.insert(dt);
			defList.insert(dd);
		}
		$('info_properties').insert(defList);
		$('info_properties').show();
	}
	if(labelEmpty && propEmpty) {
		$('info_header').innerHTML = "<i>information could not be retrieved from remote site</i>";
		$('info_header').show();
	}
}

function isEmpty(obj) {
	for(var prop in obj) {
		if(obj.hasOwnProperty(prop))
			return false;
	}
	return true;
}

function send_searches(query) {
	$('info_block').hide();
	$('search_results').show();
	$('search_result_tabs').show();
	if(query != last_query && query != "") {
		showing_results = false;
		$$(".tab").each(Element.remove);
		$$(".result_window").each(function(e) { 
			e.childElements().each(Element.remove);
			e.hide();
		});
		$('search_spinner').show();
		finders.each(function(finder) {
			finder.searchFor(query);
		});
	}
	last_query = query;
}

function send_on_return(e) {
	if(e.keyCode == 13)
		send_searches($('q').value);
}

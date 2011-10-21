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


var TagAllGlobal = new Class.create({
	initialize: function(identifier, search_domains, domain_names, domains, namespaces) {
		this.showing_results = false;
		this.last_query = null;
		this.links = [];
		this.finders = [];
		this.domains = domains;
		this.search_domains = search_domains;
		this.namespaces = namespaces;
		this.identifier = identifier;
		this.DOMAIN_NAMES = domain_names;
		this.disclaimers = {
	    "GEO": "All locations are retrieved from <a target='_blank' href='http://www.geonames.org/'>Geonames</a>.",
  	  "DBP": "All miscelaneous terms are retrieved from <a target='_blank' href='http://dbpedia.org/'>DBPedia</a>.",
    	"VIAF": "All personal names are retrieved from <a target='_blank' href='http://viaf.org/'>Virtual Authority File</a> (OCLC)."
		};
	},

	start: function() {
		$$('.tagall_search_spinner').each(Element.hide);
		$('tagall_info_block').hide();
		$('tagall_scripts').insert(new Element("script", {
			"type": "text/javascript",
			"src": "http://kbresearch.nl/portal2/jsonp.php?callback=tagall.load_links&url=" + 
				escape("http://dynamic.opendatachallenge.kbresearch.nl/database/retrieve.py?url=" + this.identifier) + 
				"&ts=" + (new Date().getTime())
		}));

		this.load_finders();
		this.links.each(function(l) { l.render() });
	},

	add_link: function(params) {
		for(var ns in this.namespaces) 
			params["uri"] = params["uri"].replace(this.namespaces[ns], ns + ":");
	
		var storeParams = {
			"url": params["identifier"],
			"label": params["label"],
			"od": params["uri"]
		};

		$('tagall_scripts').insert(new Element("script", {
			"type": "text/javascript",
			"src": "http://kbresearch.nl/portal2/jsonp.php?url=" + 
				escape("http://dynamic.opendatachallenge.kbresearch.nl/database/store.py?" + Object.toQueryString(storeParams)) 
		}));
		var link = new Link(params.label, params.uri);
		link.render();
		this.links.push(link);
	},

	load_links: function(json_links) {
	this.links = [];
	for(var x in json_links) 
		this.links.push(new Link(json_links[x].label, x));
	this.links.each(function(l) { l.render() });
	},

	load_finders: function() {
		var _this = this;
		this.search_domains.each(function(ns) {
			_this.domains[ns].each(function(domain) {
				_this.finders.push(new Finder(ns, domain));
			});
		});
	},

	get_info: function(uri) {
		$('tagall_info_block').show();
		$('tagall_info_spinner').show();
		$('tagall_info_header').hide();
		$('tagall_info_add').hide();
		$('tagall_info_flags').hide();
		$('tagall_info_properties').hide();
		$('tagall_search_results').hide();
		$('tagall_search_result_tabs').hide();
		for(ns in this.namespaces)
			uri = uri.replace(this.namespaces[ns], ns + ":");

		var _this = this;
		new Ajax.Request("info/" + uri.replace("/", ""), {
			"method": "get",
			"onSuccess": function(r) {
				_this.render_info(r.responseText.evalJSON(), uri);
			}
		}); 
	},

	render_info: function(info, uri) {
		var labelEmpty, propEmpty;
		$('tagall_info_spinner').hide();
		if(!(labelEmpty = this.isEmpty(info.label))) {
			$('tagall_info_header').innerHTML = "";
			$('tagall_info_flags').innerHTML = "";
			$('tagall_info_properties').innerHTML = "";
			$('tagall_info_add').innerHTML = "";
			if(info.thumbnail) 
				$('tagall_info_properties').insert(new Element("img", {"src": info.thumbnail, "style": "width: 80px; float: right"}));

			["en", "ja", "fr", "zh", "de", "ru", "nl", "il", "ar"].each(function(lang) {
				if(info.label && info.label[lang]) {
					var langLabel = new Element("div", {"id": "tagall_info_label_" + lang, "class": "tagall_info_label"});
					var langLink = new Element("a");
					var langImg = new Element("img", {"src": "img/flags/" + lang + ".png"});
					langLabel.insert(info.label[lang]);
					$('tagall_info_header').insert(langLabel);
					langLabel.hide();

					langLink.insert(langImg);
					$('tagall_info_flags').insert(langLink);
					langLink.observe("mouseover", function(e) {
						$$('.tagall_info_label').each(Element.hide);
						$('tagall_info_label_' + lang).show();
					});
				}
				if($('tagall_info_label_en'))
					$('tagall_info_label_en').show();
				else if($$('.tagall_info_label').length > 0)
					$$('.tagall_info_label')[0].show()
			});
			$('tagall_info_header').show();
			$('tagall_info_flags').show();
			var addLink = new Element("a");
			addLink.insert("Add this tag");	
			$('tagall_info_add').insert(addLink);
			$('tagall_info_add').show();
			var _this = this;
			addLink.observe("click", function(e) {
				if(confirm("Are you sure you want to add this tag?")) {
					_this.add_link({
						"identifier": _this.identifier,
						"uri": uri,
						"label": (info.label["en"] ? info.label["en"] : info.properties["name"])
					});
				}
			});
		}

		if(!(propEmpty = this.isEmpty(info.properties))) {
			var defList = new Element("dl");
			for(prop in info.properties) {
				var dt = new Element("dt");
				var dd = new Element("dd");
				dt.insert(prop);
				dd.insert(info.properties[prop]);
				defList.insert(dt);
				defList.insert(dd);
			}
			$('tagall_info_properties').insert(defList);
			$('tagall_info_properties').show();
		}
		if(labelEmpty && propEmpty) {
			$('tagall_info_header').innerHTML = "<i>information could not be retrieved from remote site</i>";
			$('tagall_info_header').show();
		}
	},

	isEmpty: function(obj) {
		for(var prop in obj) {
			if(obj.hasOwnProperty(prop))
				return false;
		}
		return true;
	},

	send_searches: function(query) {
		$('tagall_info_block').hide();
		$('tagall_search_results').show();
		$('tagall_search_result_tabs').show();
		if(query != this.last_query && query != "") {
			this.showing_results = false;
			$$(".tab").each(Element.remove);
			$$(".result_window").each(function(e) { 
				e.childElements().each(Element.remove);
				e.hide();
			});
			$('tagall_search_spinner').show();
			this.finders.each(function(finder) {
				finder.searchFor(query);
			});
		}
		this.last_query = query;
	},

	send_on_return: function(e) {
		if(e.keyCode == 13)
			this.send_searches($('tagall_q').value);
	}
});

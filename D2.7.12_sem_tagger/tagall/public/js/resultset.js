/*
#    resultset.js: Class representing search results in tagall 
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

var ResultSet = Class.create({

	initialize: function(json_results) {
		this.docs = json_results.docs;
		this.prettyName = json_results.pretty_name;
		this.namespace = json_results.namespace;
		this.domain = json_results.domain;
		this.numFound = json_results.numFound;
	},

	render: function() {
		if(this.docs && this.docs.length > 0) {
			var resultWindow = this.addResultWindow();
			this.addTab(resultWindow);
			this.listDocs(resultWindow);
			if(!$('disclaimer_' + this.namespace))
				resultWindow.insert("<hr id='disclaimer_"+this.namespace+"' style='clear:both' /><i>" + disclaimers[this.namespace] + "</i>");
			if(!showing_results) {
				resultWindow.show();
				$(this.namespace + "_tab").addClassName("selected");
				showing_results = true;
			}
		}
	},

	addTab: function(resultWindow) {
		if(!$(this.namespace + "_tab")) {
			var tab = new Element("a", {"id": this.namespace + "_tab", "class": "tab"});
			var lbl = new Element("div");
			lbl.insert(this.prettyName);
			tab.insert(lbl);
			$("search_result_tabs").insert(tab);
			tab.observe("click", function(e) {
				$$(".result_window").each(Element.hide);
				$$(".tab").each(function(t) { t.removeClassName("selected"); });
				tab.addClassName("selected");
				resultWindow.show();
			});
		}
	},	

	addResultWindow: function() {
		if(!$(this.namespace + "_results")) {
			var resultWindow = new Element("div", {"id": this.namespace + "_results", "class": "result_window"});
			$("search_results").insert(resultWindow);
			resultWindow.hide();
			return resultWindow;
		} else
			return $(this.namespace + "_results");
	},

	listDocs: function(resultWindow) {
		var domainDiv = $(this.namespace + "_" + this.domain); 
		if(!domainDiv) {
			domainDiv = new Element("div", {"class": "links", "id": this.namespace + "_" + this.domain});
			var label = new Element("div", {"class": "title"});
			label.insert(DOMAIN_NAMES[this.domain]);
			domainDiv.insert(label);
			resultWindow.insert(domainDiv);
		}
		var resultDiv = domainDiv.childElements().detect(function(e) { return e.hasClassName("results"); });
		if(!resultDiv) {
			resultDiv = new Element("div", {"class": "results"});
			domainDiv.insert(resultDiv);
		}
		resultDiv.childElements().each(Element.remove);
		this.docs.each(function(d) {
			var docItem = new Element("div");
			var docLink = new Element("a", {"title": d.label, "id": "target:" + d.uri});
			var infoLink = new Element("a");
			var infoImg = new Element("img", {"src": "img/information.png", "class": "tools"});
			docLink.insert(d.label.substring(0, 34));
			if(d.label.length > 34)
				docLink.insert(" (...)");
			infoLink.insert(infoImg);
			docItem.insert(infoLink);
			docItem.insert(docLink);
			resultDiv.insert(docItem);
			docLink.observe("click", function(e) {
				if(confirm("Are you sure you want to add this tag?"))
					add_link({"label": d.label, "uri": d.uri, "identifier": identifier});
			});
			infoLink.observe("click", function(e) {
				get_info(d.uri);
			});
		});
	}
});

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
			if(!$('tagall_disclaimer_' + this.namespace))
				resultWindow.insert("<hr id='tagall_disclaimer_"+this.namespace+"' style='clear:both' /><i>" + tagall.disclaimers[this.namespace] + "</i>");
			if(!tagall.showing_results) {
				resultWindow.show();
				$("tagall_" + this.namespace + "_tab").addClassName("selected");
				tagall.showing_results = true;
			}
		}
	},

	addTab: function(resultWindow) {
		if(!$("tagall_" + this.namespace + "_tab")) {
			var tab = new Element("a", {"id": "tagall_" + this.namespace + "_tab", "class": "tagall_tab"});
			var lbl = new Element("div");
			lbl.insert(this.prettyName);
			tab.insert(lbl);
			$("tagall_search_result_tabs").insert(tab);
			tab.observe("click", function(e) {
				$$(".tagall_result_window").each(Element.hide);
				$$(".tagall_tab").each(function(t) { t.removeClassName("selected"); });
				tab.addClassName("selected");
				resultWindow.show();
			});
		}
	},	

	addResultWindow: function() {
		if(!$("tagall_"  + this.namespace + "_results")) {
			var resultWindow = new Element("div", {"id": "tagall_" + this.namespace + "_results", "class": "tagall_result_window"});
			$("tagall_search_results").insert(resultWindow);
			resultWindow.hide();
			return resultWindow;
		} else
			return $("tagall_" + this.namespace + "_results");
	},

	listDocs: function(resultWindow) {
		var domainDiv = $("tagall_" + this.namespace + "_" + this.domain); 
		if(!domainDiv) {
			domainDiv = new Element("div", {"class": "tagall_links", "id": "tagall_" + this.namespace + "_" + this.domain});
			var label = new Element("div", {"class": "tagall_title"});
			label.insert(tagall.DOMAIN_NAMES[this.domain]);
			domainDiv.insert(label);
			resultWindow.insert(domainDiv);
		}
		var resultDiv = domainDiv.childElements().detect(function(e) { return e.hasClassName("results"); });
		if(!resultDiv) {
			resultDiv = new Element("div", {"class": "tagall_results"});
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
					tagall.add_link({"label": d.label, "uri": d.uri, "identifier": tagall.identifier});
			});
			infoLink.observe("click", function(e) {
				tagall.get_info(d.uri);
			});
		});
	}
});

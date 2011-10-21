/*
#    link.js: Class representing resource link in tagall 
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

var Link = Class.create({

	initialize: function(label, uri) {
		this.label = label;
		this.uri = uri;
		this.url = this.uri;
		for(ns in namespaces)
			this.url = this.url.replace(ns + ":", namespaces[ns]);
	},

	render: function() {
		if(!$(this.uri)) {
			var newLink = new Element("div", {"id": this.uri});
			var infoLink = new Element("a", {"href": this.url, "target": "_blank"});
			var deleteLink = new Element("a");
			var deleteImg = new Element("img", {"src": "img/delete.png", "class": "tools"});
			deleteLink.insert(deleteImg);
			infoLink.insert(this.label);
			newLink.insert(deleteLink);
			newLink.insert(infoLink);
			$("user").insert(newLink);
			var curLink = this;
			deleteLink.observe("click", function(e) {
				if(confirm("Are you sure you want to remove this tag?"))
					curLink.drop()
			});
		}
	},

	drop: function() {
		var delUri = this.uri;
		new Ajax.Request("/database/delete.py?" + Object.toQueryString({"url": identifier, "od": this.uri}), {
			method: "get",
			onSuccess: function(r) {
//				var rlink = r.responseText.evalJSON();
				$(delUri).remove();
				links = links.reject(function(l) { return l.uri == delUri; });
			}
		});
	}
});

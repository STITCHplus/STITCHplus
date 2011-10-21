/*
#    finder.js: Send searches for tagall 
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

var Finder = Class.create({
	initialize: function(namespace, domain) {
		this.parameters = {
			namespace: namespace,
			domain: domain,
			start: 1,
			limit: 10,
			query: ""
		}
		this.resultSets = [];
		this.currentResultSet = 0;
		this.numFound = 0;
	},
	searchFor: function(query) {
		this.parameters.query = query;
		this.parameters.start = 1;
		this.doSearch();
	},
	addMoreLink: function() {
		var resultWindow = $(this.parameters.namespace + "_" + this.parameters.domain);
		if(resultWindow) {
			var moreLink = resultWindow.childElements().detect(function(e) { return e.hasClassName("more_link") });
			if(!moreLink) {
				var currentFinder = this;
				moreLink = new Element("a", {"class": "more_link"});
				moreLink.insert("More &gt;&gt;");
				resultWindow.insert(moreLink);
				moreLink.observe("click", function(e) {
					currentFinder.moreResults();
				});
			}
		}
	},
	addLessLink: function() {
		var resultWindow = $(this.parameters.namespace + "_" + this.parameters.domain);
		if(resultWindow) {
			var lessLink = resultWindow.childElements().detect(function(e) { return e.hasClassName("less_link") });
			if(!lessLink) {
				var currentFinder = this;
				lessLink = new Element("a", {"class": "less_link"});
				lessLink.insert("&lt;&lt; Back");
				resultWindow.insert(lessLink);
				lessLink.observe("click", function(e) {
					currentFinder.backTrack();
				});
			}
		}
	},
	dropLink: function(lclass) {
		var resultWindow = $(this.parameters.namespace + "_" + this.parameters.domain);
		if(resultWindow) {
			var link = resultWindow.childElements().detect(function(e) { return e.hasClassName(lclass) });
			if(link)
				link.remove();
		}
	},
	paginate: function() {
		if(this.parameters.start < this.numFound)
			this.addMoreLink();
		else
			this.dropLink("more_link");

		if(this.parameters.start - 10 > 1)
			this.addLessLink();
		else
			this.dropLink("less_link");
	},
	digestResults: function(resultSet) {
		resultSet.render();
		this.currentResultSet = this.resultSets.length;
		this.resultSets.push(resultSet);
		this.numFound = resultSet.numFound;
		this.parameters.start += 10;
		this.paginate();
	},
	backTrack: function() {
		this.resultSets[--this.currentResultSet].render();
		this.parameters.start -= 10;
		this.paginate();
	},
	moreResults: function() {
		if(this.resultSets.length - 1 > this.currentResultSet) {
			this.resultSets[++this.currentResultSet].render();
			this.parameters.start += 5;
			this.paginate();
		} else {
			var resultDiv = $(this.parameters.namespace + "_" + this.parameters.domain).childElements().detect(function(e) { return e.hasClassName("results"); });
			if(resultDiv) {
				var spinner = resultDiv.childElements().detect(function(e) { return e.hasClassName("search_spinner"); });
				resultDiv.childElements().each(Element.hide);
				if(!spinner) {
					spinner = new Element("img", {"src": "img/spinner.gif", "class": "search_spinner"});
					resultDiv.insert(spinner);
				} else
					spinner.show();
			}
			this.doSearch();
		}
	},
	doSearch: function() {
		var currentFinder = this;
		new Ajax.Request("find_by_params?" + Object.toQueryString(this.parameters), {
			method: "get",
			onSuccess: function(resp) {
				$$('.search_spinner').each(Element.hide);
				var resultSet = new ResultSet(resp.responseText.evalJSON());
				currentFinder.digestResults(resultSet);
			}
		});
	}
});

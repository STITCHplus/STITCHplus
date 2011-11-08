var max_docs = 0, min_year = 1900, max_year = 2011;
var counts = {};
var current_facet = "";
var current_year = null;
var docs = [];
var dragging_slider = false;
var sliderX = 0;
var slide_bar_width = null;

function pretty_month(m) {
	var months_short = ["", "Jan", "Feb", "Mrt", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"]
	return months_short[m];
}

function cleanup_highlight(str) {
	return str.replace(/<\/?p>/g, " ").replace(/^>/, "");
}

function facet_search(facet_name, in_year) {
	var year_select = (in_year ? " AND date_year_date:%22"+ in_year +"-01-01T00:00:00Z%22" : "")
	current_year = in_year;
	current_facet = facet_name;
	if($('slide_wrap'))
		$('slide_wrap').style.display = "none";
	new Ajax.Request(baseQuery + year_select + "&facet.field=date_" + facet_name + "_date&facet=true&fl=facet_fields&wt=json", {
		onSuccess: function(response) {
			build_histogram(response.responseText.evalJSON().facet_counts.facet_fields["date_" + current_facet + "_date"], current_facet);
		}
	});
}

function object_search(start) {
	if(current_year) {
		$('spinner').style.display = "block";
		if($('highlight_scroll')) $('highlight_scroll').remove();
		if(start == null) start = 0;
		var year_select = " AND date_year_date:%22" + current_year + "-01-01T00:00:00Z%22";
		new Ajax.Request(baseQuery + year_select + "&rows=1000&fl=date_date,identifier&wt=json&hl=true&hl.fl=text&start=" + start, {
			onSuccess: function(response) {
				var resp = response.responseText.evalJSON();
				digest_docs(resp);
				if(resp.response.numFound > resp.response.start) 
					object_search(start + 1000);
				else {
					$('spinner').style.display = "none";
					$('slide_wrap').style.display = "block";
					start = null;
					load_snippets(resp);
				}
			}
		});
	}
}

function digest_docs(resp) {
	for(var i = 0; i < resp.response.docs.length; ++i) {
		docs.push({
			id: resp.response.docs[i]["identifier"],
			highlight: (resp.highlighting[resp.response.docs[i]["identifier"]].text ? resp.highlighting[resp.response.docs[i]["identifier"]].text[0] : "&nbsp;"),
			days: parseInt((date_key_from_date(resp.response.docs[i]["date_date"][0], "month")-1)*30) + parseInt(date_key_from_date(resp.response.docs[i]["date_date"][0], "day")),
			full_date: date_key_from_date(resp.response.docs[i]["date_date"][0], "date")
		});
	}
}

function load_snippets(resp) {
	digest_docs(resp);
	docs = docs.sortBy(function(d) { return d.days });
	for(var i = 0; i < docs.length; ++i) {
		$('detail_view').insert(
			"<span id=\"" + docs[i].id[0].replace(/[^=]+=/, "") + "\" style=\"left:" + (docs[i].days*4) + "px\" class='highlight'>" +
			"<a title=\"" + pretty_date(docs[i].full_date) + "\" href=\"#\"><img src=\"img/bullet_green.png\" /></a>" +
			cleanup_highlight(docs[i].highlight) +
			"</span>"
		);
	}
	view_snippets(0);
}

function view_snippets(start) {
	start = start > docs.length - 1 ? docs.length - 1 : start;
	$$('.highlight').each(function(h) {h.style.display = "none"; });
	$$('.month_name').each(function(m) {m.style.color = "#aaa"});
	$$('.hist_bar').each(function(b) {b.style.backgroundColor = "blue"});
	var sMon = Math.floor(docs[start].days / 30)+1;
	if($('month_name_' + sMon)) $('month_name_' +sMon).style.color = "#faa";
	if($('bar_' + sMon)) $('bar_' + sMon).style.backgroundColor = "red";
	for(var i = start; i < (docs.length < start + 5 ? docs.length : start + 5); ++i) {
		$(docs[i].id[0].replace(/[^=]+=/, "")).style.display = "block";
	}
	if(!$('highlight_scroll'))
		view_highlight_slider(start);
}

function view_highlight_slider(start) {
	var slider_pos = calculate_slider_position(start);	
	$('highlight_slider').insert(
		"<div id=\"highlight_scroll\" style=\"width: " + slider_pos.width + "px;left: " + slider_pos.left + "px;\">" +
		"	<a id=\"highlight_drag\" onmousedown='start_dragging_slider(event)' onmouseup='stop_dragging_slider(event)' onmousemove='drag_slider(event)'" +
		">||</a>" +
		"</div>"
	);
	move_highlights_to(docs[start].days, slider_pos.left);
}

function start_dragging_slider(e) {
	dragging_slider = true;
	sliderX = e.clientX;
}

function stop_dragging_slider(e) {
	dragging_slider = false;
}

function drag_slider(e) {
	if(dragging_slider) {
		slide_slider(sliderX - e.clientX);
		sliderX = e.clientX;
	}
}

function slide_slider(dir) {
	var pix_factor = 450 / (12*30);
	var slider_left = parseInt($('highlight_scroll').style.left) - dir;
	if(slider_left > 430) slider_left = 430;
	if(slider_left < 0) slider_left = 0;
	var day = Math.floor(slider_left / pix_factor);
	var cur_doc = 0;
	for(var i = 0; i < docs.length; ++i) {
		if(docs[i].days >= day) {
			cur_doc = i;
			break
		}
	}
	var end = (docs.length < cur_doc + 5 ? docs.length - 1 : cur_doc + 4);
	var max_days_view = docs[end].days;
	var slider_right = pix_factor * max_days_view;
	if(slider_right > 450) slider_right = 450;
	if(slider_right < 20) slider_right = 20;
	var slider_width = (slider_right - slider_left) < 20 ? 20 : (slider_right - slider_left);
	$('highlight_scroll').style.left = slider_left + "px";
	$('highlight_scroll').style.width = slider_width + "px";	
	move_highlights_to(day, slider_left);
	view_snippets(i);
}

function calculate_slider_position(start) {
	var end = (docs.length < start + 5 ? docs.length - 1 : start + 4);
	var max_days_view = docs[end].days;
	var pix_factor = 450 / (12*30);
	var slider_left = pix_factor * docs[start].days;
	var slider_right = pix_factor * max_days_view;
	var slider_width = (slider_right - slider_left) < 20 ? 20 : (slider_right - slider_left);
	return {left: slider_left, width: slider_width};
}

function slide_to_month(month) {
	var startdoc_index = 0;
	var start_pos = 0;
	for(var i = 0; i < docs.length; ++i) {
		if(parseInt(date_key_from_date(docs[i].full_date, "month").replace(/^0/, "")) == month) {
			startdoc_index = i;
			start_pos = docs[i].days;
			break;
		}
	}
	var slider_pos = calculate_slider_position(startdoc_index);
	$('highlight_scroll').style.left = slider_pos.left + "px";
	$('highlight_scroll').style.width = slider_pos.width + "px";
	move_highlights_to(start_pos, slider_pos.left);
	view_snippets(startdoc_index);
}

function move_highlights_to(start, slider_left) {
	$('month_bar').style.left = (-(start*4) + slider_left) + "px";
	docs.each(function(d) {
		$(d.id[0].replace(/[^=]+=/, "")).style.left = (((d.days - start) * 4) + slider_left) + "px";
	});
}

function add_year_guide(year, left, nDocs, key) {
	if($('year_guide')) {
		$('year_guide').style.left = left + "px";
		$('year_guide').innerHTML = (key == "month" ? pretty_month(year): year) + " (" + nDocs + ")";
	} else {
		$('guide').insert("<span id='year_guide' class='guide_year' style='left:" + left + "px;'>" + (key == "month" ? pretty_month(year): year) + " (" + nDocs + ")</span>");
	}
}

function date_key_from_date(str, date_key) {
	if(date_key == "year") return str.replace(/\-.*$/, "");
	else if(date_key == "month") return str.replace(/^\d{4}\-/, "").replace(/\-\d{2}.*$/, "");
	else if(date_key == "day") return str.replace(/^\d{4}\-\d{2}\-/, "").replace(/T.+$/, "");
	else if(date_key == "date") return str.replace(/T.+$/, "");
	else if(date_key == "days") return parseInt((date_key_from_date(str, "month")-1)*30) + parseInt(date_key_from_date(str, "day"));
}

function pretty_date(str) {
	return str;
}

function build_histogram(date_fields, key) {
	counts = {};
	for(var i = 0; i < date_fields.length; i+=2) {
		var date_key = date_key_from_date(date_fields[i], key);
		if(counts[date_key]) counts[date_key] += date_fields[i+1];
		else counts[date_key] = date_fields[i+1];
	}
	var keys = [];
	var max_docs = 0;
	for(var i in counts) {
		if(counts[i] > 0)
			keys.push(i);
		max_docs = counts[i] > max_docs ? counts[i] : max_docs;
	}
	var years = keys.sort();
	if(key == "year") {
		min_year = parseInt(years[0]);
		max_year = parseInt(years[years.length-1]);
	} else {
		min_year = 1;
		max_year = 12;
	}
	var width = Math.floor(800 / (max_year - min_year + 2));
	var cum_width = 0;
	$('timeline').innerHTML = "";
	if(key == "month") 
		$('back').innerHTML = "<a style='float: left' href='#' onclick='facet_search(\"year\")'>&lt;&lt;</a>&nbsp;<b>" + current_year + "</b>";
	else
		$('back').innerHTML = "";
	for(var i = min_year; i <= max_year; ++i) {
		var nDocs = counts[(i < 10 ? "0" : "") + i] ? counts[(i < 10 ? "0" : "") + i] : 0;
		if(nDocs > max_docs) max_docs = nDocs;
		var height = (150 / max_docs) * nDocs;
		var htop = 150 - height;
		var click_func = (key == "year" ? "facet_search(\"month\", "+i+"); docs = []; $(\"detail_view\").innerHTML =\"\";object_search()" : "slide_to_month("+i+")");
		$('timeline').insert("<div id='bar_"+i+"' class='hist_bar' style='height:" + (height+1) + "px; width:" + width + "px;top:" + htop + "px;' onmouseover='this.style.backgroundColor=\"red\"; add_year_guide("+i+", "+(cum_width*0.95) +", "+nDocs+", \""+key+"\")' onmouseout='this.style.backgroundColor=\"blue\"' onclick='" + click_func + "'>&nbsp;</div>");
		cum_width += width;
	}
	$('timeline').insert("<div id='guide' style='clear:both; width: "+cum_width+"px'></div>");
	if(key == "month") {
		$('guide').insert("<span class='guide_year' style='float:left'>Januari</span>");
		$('guide').insert("<span class='guide_year' style='float:right'>December</span>");
	} else {
		$('guide').insert("<span class='guide_year' style='float:right'>" + max_year + "</span>");
		$('guide').insert("<span class='guide_year' style='float:left'>" + min_year + "</span>");
	}
}

window.onload = function() {
	facet_search("year");
}

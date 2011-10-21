# How can I embed TAGall in my site ?

To embed TAGall in your site, you have to include an external javascript, add some javascript code, and place a target div on your site.

Step 1 : Include external javascript.
<script type="text/javascript" src="http://opendatachallenge.kbresearch.nl/js/easyXDM/easyXDM.js"></script>

Step 2 : Add javascript.
<script type="text/javascript"> function urlencode (str) { str = (str + '').toString(); return encodeURIComponent(str).replace(/!/g, '%21').replace(/'/g, '%27').replace(/\(/g, '%28').replace(/\)/g, '%29').replace(/\*/g, '%2A').replace(/%20/g, '+'); } // This will contain the easyXDM socket object var socket = null; // Url-encoded reference to the website you want to tag alert('change http://your.domain.org/ to your url'); var url_reference = urlencode("http://your.domain.org/"); // Id attribute of the div which will contain the tagAll app var target_div = "your_div_id" /** Initialize the websocket to tagall app using easyXDM **/ function initialize_tagall_socket() { socket = new easyXDM.Socket({ remote: "http://dynamic.opendatachallenge.kbresearch.nl/?id=" + url_reference + "&socket=true", container: target_div, onReady: function() { document.getElementById(target_div).childNodes[0].height = "95%"; } }); } /** Use easyXDM socket to post a search term to tagall app **/ function post_word_to_tagall(word) { socket.postMessage(word); } initialize_tagall_socket(); </script>

Step 3 : Place a target div.
<button onclick="post_word_to_tagall('test')">Test</button> <div style="float:right" height="300px" id="your_div_id"></div>
# How can I retrieve the data related to my URL?

You can retrieve data on a particular URL by retrieving a JSON response from : http://dynamic.opendatachallenge.kbresearch.nl/database/retrieve.py?url= URL to view
For example http://dynamic.opendatachallenge.kbresearch.nl/database/retrieve.py?url=http://opendatachallenge.kbresearch.nl.
# How can I show the number of tags on a page to my visitors ?

To show the number of tags on your website embed the following iframe on the page. <iframe src="http://dynamic.opendatachallenge.kbresearch.nl/database/count_all.py" width=340 height=60 scrolling="no" f

# What language is TAGall written in ?

TAGall is mainly written in Ruby. As a database back-end MongoDB was chosen with a Python wrapper, which handles the storage and retrieval actions.
# What are the dependencies ?

	apt-get install mongodb ruby rubygems python-pymongo libxslt-dev
	gem install mongrel sinatra ruby-xslt json
		

# How do I install TAGall on my own machine ?

Install the dependencies, start MongoDB, get the TAGall source code, copy the database scripts to your Apache setup, and let Apache execute the Python scripts.
Finally start the TAGall Ruby instance by running:

ruby -rubygems ./tagall.rb -p4000

# How do I configure TAGall to use different a LinkedOpenData resource ?

This is handled through the config file located in:

	./config/config.json

The linked data resource will also need to be indexed in an open search endpoint generating XML-results. These xml-results need to be converted to standardized JSON using a XSLT-stylesheet. For an example of such a stylesheet see:

	./public/stylesheets/dbp2json.xsl
		

A similar stylesheet is required to generate info-blocks about a given resource link:

	./public/stylesheets/dbp_info2json.xsl
		

# Step 1: Set up a namespace to translate the resource links (effectively generating 'persistent' identifiers):

	"namespaces": {
		"DBP": "http://dbpedia.org/resource/",
	}, ...
		

# Step 2: Set up the base url and suffix used to retrieve data for the resource links:

	"info_namespaces": {
		"DBP": ["http://dbpedia.org/data/", ".rdf"]
	}, ...
		

# Step 3: Create an array containing the search domains avaiable for the open search endpoint for this resource:

	"domains": {
		"DBP":  [
			"orgParam",
			"personParam",
			"placeParam"
		]
	}, ...
		

# Step 4: Create a localized name for your resource.

	"prettyNames": {
		"DBP": "Miscelaneous"
	}, ...
		

# Step 5: Add your resource to the available search domains.

	"search_domains": [
		"DBP"
	], ...
		

# Step 6: Configure the search-endpoint you want to send your queries to.

	"search": {
		"DBP": {
			"baseUrl": "http://lookup.dbpedia.org/api/search.asmx/KeywordSearch?",
			"queryParam": "QueryString=",
			"queryConcat": " ",
			"startParam": null,
			"maxParam": "MaxHits",
			"personParam": "",
			"orgParam": "",
			"placeParam": "",
			"info_stylesheet": "public/stylesheets/dbp_info2json.xsl",
			"stylesheet": "public/stylesheets/dbp2json.xsl",
			"start_correction": 0
		},
	}, ...
		

(synopsis)

baseUrl
    Root of the search endpoint
queryParam
    Parameter for full-text queries
queryConcat
    Concatenation rules for whitespace in query (ex: " AND "
startParam
    (Optional), needed if endpoint supports pagination
[person|org|place]Param
    (Optional), param for searchdomain restriction (ex: "personParam": "type=person")
info_stylesheet
    Reference to stylesheet converting your resource link XML to standardized JSON
stylesheet
    Reference to stylesheet converting your resource's search results to standardized JSON
start_correction
    (Optional) Some endpoints' pagination work with 0 as a start index, others with 1. We default to 1, so use -1 to correct this. 

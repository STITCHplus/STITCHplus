<?php
	// This script should return all the tags belonging to the url in the params
	//	params:
	//		"url": the url of the location being tagged (a different identifier is fine too, of course)
	// The url being tagged
	$url = $_GET["url"];

	// The code below reads the sample.txt file, 
	// Here your script source should return the results for the following pseudo-query as json:
	// SELECT * FROM yourDataSource WHERE url=$_GET["url"]
	// sample json: 
	// {
	// 	"your:tag:uri": 	{"label": "Your Tag Label"}, 
	//	"tag:2": 					{"label": "Label 2"}
	// }
	$lines = split("\n", file_get_contents("sample.txt"));
	$resp = array();
	foreach($lines as $line) {
		$parts = split(";", $line);
		if($parts[0] == $url) {
			array_push($resp, "\"" . $parts[1] . "\": {\"label\": \"" . $parts[2] . "\"}");
		}
	}
	echo "{";
	for($i = 0; $i < count($resp); ++$i) {
		echo $resp[$i];
		if($i < count($resp) - 1)
			echo ",";
	}
	echo "}"
?>

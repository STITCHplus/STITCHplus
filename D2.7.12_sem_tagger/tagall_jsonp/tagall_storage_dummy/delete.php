<?php	
	// This script should be used to remove a tag from your data source
	// params:
	//	"url": the url being tagged
	//	"od": the uri of the tag

	// The script below should reflect the following pseudo-query
	// DELETE FROM yourDataSource WHERE "url" = $_GET["url"] AND "od" = $_GET["od"]
	$lines = split("\n", file_get_contents("sample.txt"));
	$outlines = "";
	foreach($lines as $line) {
		$parts = split(";", $line);
		if(!($parts[0] == $_GET["url"] && $parts[1] == $_GET["od"]))
			$outlines .= $line . "\n";
	}

	$hndl = fopen("sample.txt", "w");
	fwrite($hndl, $outlines);
	fclose($hndl);

?>

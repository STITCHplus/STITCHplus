<?php
	// This script should add a new tag to your data source
	// params: 
	//  "url" -> the site being tagged
	//  "od"  -> the URI of the tag
	//  "label" -> the label of the tag
	$hndl = fopen("sample.txt", "a");
	// IF NOT EXISTS $_GET["url"] COMBINED WITH $_GET["od"]
		fwrite($hndl, $_GET["url"] . ";" . $_GET["od"] . ";" . $_GET["label"] . "\n");
	// echo "ok"
	// ELSE
	// echo "already exists"
	// ENDIF
	fclose($hndl);
?>

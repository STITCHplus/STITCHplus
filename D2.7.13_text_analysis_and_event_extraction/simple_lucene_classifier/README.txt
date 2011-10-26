Simple command line classifier-tool using lucene.

Uses the content of a small sample set of tagged records to define a list of most relevant terms (using lucene tf_idf scoring mechanism + search and retrieval) per class.

The tag_data.json file contrains three concept classes, connected to the ANP press OCR data:
- Cold War
- China
- Hunger

dependencies:
ruby1.8
gems:
json >= 1.46

Sample output:



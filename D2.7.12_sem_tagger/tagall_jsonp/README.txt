Tagall jsonp:

Uses jsonp protocol to run a semantic tagger, for details see: ../tagall/README.txt

to run sources, install gem dependencies:
sinatra >= 1.1.2 
ruby-xslt >= 0.9.8

run:
# ruby -rubygems tagall.rb -p3000

to test open demo.html in your favourite browser

IMPORTANT NOTE:
 this instance of the tagger is hard coded to communicate with the following python scripts via URL, possibly requests will be blocked:
http://dynamic.opendatachallenge.kbresearch.nl/database/retrieve.py
http://dynamic.opendatachallenge.kbresearch.nl/database/delete.py
http://dynamic.opendatachallenge.kbresearch.nl/database/store.py

Please set up your own storage mechanism and endpoint for continual use
For an example see: 

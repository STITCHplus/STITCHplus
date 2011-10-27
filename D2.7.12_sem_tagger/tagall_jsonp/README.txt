Tagall jsonp:

Uses jsonp protocol to run a semantic tagger, for details see: ../tagall/README.txt

Getting started:
	Install ruby1.8
	Install rubygems
	Install apache 2 with php4 or higher

Install gem dependencies:
	sinatra >= 1.1.2 
	ruby-xslt >= 0.9.8
	json >= 1.4.6

Run:
	# ruby -rubygems tagall.rb -p3000
	(This will startup the backend application)

To test, symlink the tagall_storage_dummy folder to your public htaccess folder:
	# cd /var/www
	# sudo ln -s /path/to/tagall_jsonp/tagall_storage_dummy

And surf to:
	http://localhost:3000/demo.html 
  ... in your favourite browser

Please set up your own storage mechanism and endpoint for continual use
For an example using mongodb see: 
	https://github.com/STITCHplus/STITCHplus/tree/master/D2.7.12_sem_tagger/store_and_retrieve_example 

To modify for different search endpoints, reference to the storage url, etc:
 - edit config/config.json
 - write new transformation XSLT-stylesheets (to convert open search responses to the proper json)
 - write your own storage endpoint
 - current xsl-stylesheets are located in:
 https://github.com/STITCHplus/STITCHplus/tree/master/D2.7.12_sem_tagger/tagall_jsonp/public/stylesheets
 - the generated javascripts used are in:
	https://github.com/STITCHplus/STITCHplus/blob/master/D2.7.12_sem_tagger/tagall_jsonp/views/jsonp.erb 
 - but the separate js objects are also (unused) in:
 https://github.com/STITCHplus/STITCHplus/tree/master/D2.7.12_sem_tagger/tagall_jsonp/public/js
 
 
 

#!/usr/bin/ruby
require 'rubygems'
require 'mongo'
require 'json'
require 'simple_get_response'
require 'viaf_matcher'

offset = File.exists?("offset") ? File.open("offset", "r") {|f| f.read}.to_i : 0

save_collection = Mongo::Connection.new("kbresearch.nl", 27017).db("expand")["ggc_thes"]
while(true)
	resp = SimpleGetResponse.new("http://kbresearch.nl/solr/ggc-thes/raw/select?q=inScheme:%20%22Persoonsnamen%22&wt=json&sort=ggchits_int%20desc&start=#{offset}")
	if resp.success?
		break if offset > JSON.parse(resp.body)["response"]["numFound"] 
		offset += 10
		File.open("offset", "w") {|f| f.write(offset)}

		docs = JSON.parse(resp.body)["response"]["docs"]
		docs.each do |doc|
			test = save_collection.find_one("_id" => doc["id"].sub("GGC-THES:AC:", ""))
			if(test && test["sameAs"]["VIAF"])
				puts "ALREADY LINKED"
			else
				labels = doc["prefLabel"] + (doc["altLabel"] || [])
				death_date = doc["end_date"][0].to_i if doc["end_date"]
				birth_date = doc["start_date"][0].to_i if doc["start_date"]
				scores = ViafMatcher.scores(labels, birth_date, death_date)
        if scores.length > 0 && scores[0][:score] >= 50 
					match_found = true
			    save_id = doc["id"].sub("GGC-THES:AC:", "")
    	    save_record = save_collection.find_one("_id" => save_id)
			    save_record ||= {"_id" => save_id}
   	      save_record["sameAs"] ||= {}
			    save_record["sameAs"]["VIAF"] ||= [] 
					unless save_record["sameAs"]["VIAF"].map{|l| l["id"]}.include?(scores[0][:uri])
        	  save_record["sameAs"]["VIAF"] << {
			    	  "id" => scores[0][:uri],
   	        	"score" => scores[0][:score]
				    }
 	    	    puts "DATA SAVED: " + save_record.inspect
						save_collection.save(save_record)
					else
						puts "ALREADY LINKED"
					end
				end

			end
     end
		end
	puts "=============== OFFSET #{offset} ============="
end

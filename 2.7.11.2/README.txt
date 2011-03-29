STITCHplus deliverable.

(2.7.11.1 Matching Nederlandse persoonsnamen en concepten uit de GOO met DBpedia)

Project : 

    KB thesauri matching to DBpedia.

Prerequisites : 

    - Python3
    - SOLR installed on Tomcat 
        For creating an index from DBPedia data.
    - MongoDB 
        For storing the matches made.

Process : 

    First we'll create an index existing of DBpedia data.
    Then we'll be matching the (kb-thesauri) sample data to the DBpedia index, 
    and store the results in an MongoDB server for usage later on.

    Step 1 : 

        Create an extra solrCore in Tomcat, using the schema in the directory solr-config directory.
        (for more information on setting up an SOLR/Tomcat server see : http://wiki.apache.org/solr/SolrTomcat ) 
        It must be reachable via curl -s localhost:8080/solr/dbpedia/

    Step 2 :
        
        Start the DBpedia harvester, and wait for the index to be filled.

        ./dbpedia/DBpedia_to_solr.py

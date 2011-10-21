#!/usr/bin/env python2.6

import sys, os, re

from xml.etree.ElementTree import Element
from xml.etree import ElementTree as etree
from xml.etree.ElementTree import SubElement

import simplejson, urllib
from pprint import pprint


SOLR_baseurl = "http://localhost:8080/solr/dbpedia/select"

def parse_thesauri_records(path= "kb_thesauri"+os.sep+"thesauri_data_example1.xml", DEBUG=True):
    '''
        Read thesauri records from file, and parse these records.
        
        On a record base, the type is determined, if the type is a person, 
        find out if there is a year of birth or a year of death.

        Returns a array of (dicts) records, containing a shortname, fullname, and dates if found.
    '''
    try:
        fh = open (path, 'r')
        #fh= urllib.urlopen('http://serviceso.kb.nl/mdo/oai?verb=ListRecords&set=GGC-THES&metadataPrefix=dcx&resumptionToken=GGC-THES!!!dcx!1368800')
        xml_data = etree.fromstring(fh.read())
        fh.close()
    except:
        sys.stderr.write("Could not read " + path)
        os._exit(-1)

    count = 0 
    place_count = 0
    person_count = 0

    records = []

    xml_data = xml_data.find('{http://www.openarchives.org/OAI/2.0/}ListRecords')
    for item in xml_data:
        if item.find('{http://www.openarchives.org/OAI/2.0/}metadata'):
            count += 1

            id = False
            type = False
            label = False

            for name in item.find('{http://www.openarchives.org/OAI/2.0/}metadata').getiterator():
                # Itterate over the metadata objects
                if name.tag.endswith('Concept'):
                    # Get the KB thesauri id
                    id = name.attrib.values()[0]
                if name.tag.endswith('inScheme'):
                    for i in name.attrib.values():
                        if i.find('geografisch') > -1:
                            type='place'
                            place_count += 1
                if name.tag.endswith('type'):
                    if name.text == "persoon" or name.text == 'person':
                        type = "person"
                        person_count += 1
                if name.tag.endswith('prefLabel'):
                    label = unicode(name.text).encode('utf-8').strip()
                    shortname = label.split('(')[0].strip()


                    # Find year of birth/death in the prefLabel
                    # possible forms  

                    # Willem Jan (1900) == yob
                    # Willem Jan (1900-) == yob
                    # Willem Jan (-1900) == yod

                    dobfind = label.replace(shortname, '')
                    yob = ""
                    yod = ""
                    if len(dobfind) > 0:
                        date_extract = re.findall('\d{4}', dobfind)

                        if len(date_extract) == 2:
                            if date_extract[0] < date_extract[1]:
                                yob = str(date_extract[0])
                                yod = str(date_extract[1])
                            else:
                                yob = str(date_extract[1])
                                yod = str(date_extract[0])

                        if len(date_extract) == 1:
                            if dobfind[dobfind.find(date_extract[0]):].find('-') > -1:
                                yob = date_extract[0]
                            else:
                                yod = date_extract[0]

            if label:
                record = {"label" : label, "shortname" : shortname, "type" : type , "id" : id}
                if len(yob) > 0:
                    record['yob'] = yob
                if len(yod) > 0:
                    record['yod'] = yod

                records.append(record)

    if DEBUG:
        print("parsed " + str(len(records)))
    return(records)

nrecords = []
#
# Try to match each thesauri to an DBpedia record, the type of thesauri record is leadign.
# If the type was defined either as a place or a person, this will boost the score for the match.
# For places : A literal match on the label will boost the match.
# For persons : A match on the DOB / DOD will boost the matching score.
#
for item in parse_thesauri_records():
    certain = 0 
    if item["type"] == "person":
        url = SOLR_baseurl + "?q=type_str:person%20AND%20label:" + urllib.quote(item["shortname"])+"&wt=json"
        certain += 20
    elif item["type"] == "place":
        url = SOLR_baseurl + "?q=type_str:place%20AND%20((" + urllib.quote(item["label"])+")%20OR%20label:"+urllib.quote(item["label"])+")&wt=json"
        certain += 20
    else:
        url = SOLR_baseurl + "?q=" + urllib.quote(item["shortname"])+"&wt=json"

    response = simplejson.loads(urllib.urlopen(url).read().decode('utf-8'))

    item['dbpedia_match'] = False
    item['dbpedia_certain'] = certain

    if response['response']['numFound'] > 0:
        if item["type"] == "person":
            for r in response['response']['docs']:
                if 'dob' in r.keys() and 'yob' in item.keys():
                    if item['yob'] == r['dob'][0][:4]:
                        item["dbpedia_match"] = r['id']
                        # If the thesauri record yob matches dob from dbpedia, add bonus points to the score.
                        item["dbpedia_certain"] += 20
                        break
                if 'dob' in r.keys() and 'yob' in item.keys():
                    if item['yob'] == r['dob'][0][:4]:
                        # If the thesauri record yod matches dod from dbpedia, add bonus points to the score.
                        item["dbpedia_match"] = r['id']
                        item["dbpedia_certain"] += 20
                        break
        elif item["type"] == "place":
            for dbp in response['response']['docs']:
                if item["shortname"].lower() == dbp["label"][0].lower():
                    certain += 20
                    # If the label == prefLabel than add bonus points.
                    item["dbpedia_match"]  = dbp['id']
                    item["dbpedia_certain"] = certain
                    break
                else:
                    item["dbpedia_match"]  = dbp['id']
                    item["dbpedia_certain"] = certain
                    break

    nrecords.append(item)

for item in nrecords:
    if "dbpedia_match" in item.keys():
        if item['dbpedia_match']:
            print(item['id'] +" =~ "+ item['dbpedia_match'] + " score " + str(item['dbpedia_certain']))

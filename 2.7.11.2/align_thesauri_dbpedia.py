#!/usr/bin/env python


from xml.etree.ElementTree import Element
from xml.etree import ElementTree as etree
from xml.etree.ElementTree import SubElement

import simplejson, urllib
from pprint import pprint

import os,re


SOLR_baseurl = "http://localhost:8080/solr/dbpedia/select"

data = "kb_thesauri" + os.sep + "thesauri_data_example1.xml"

fh = open (data, 'r')
xml_data = etree.fromstring(fh.read())
fh.close()


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
            if name.tag.endswith('Concept'):
                id = name.attrib.values()[0]
            if name.tag.endswith('inScheme'):
                for i in name.attrib.values():
                    if i.find('geografisch') > -1:
                        type='place'
                        place_count += 1
                        break
            if name.tag.endswith('type'):
                if name.text == "persoon" or name.text == 'person':
                    type = "person"
                    person_count += 1
            if name.tag.endswith('prefLabel'):
                label = unicode(name.text).encode('utf-8').strip()
                shortname = label.split('(')[0].strip()

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

nrecords = []

for item in records:
    certain = 0
    if item["type"] == "person":
        url = SOLR_baseurl + "?q=type_str:person%20AND%20label:\"" + urllib.quote(item["shortname"])+"\"&wt=json"
        certain += 20
    elif item["type"] == "place":
        url = SOLR_baseurl + "?q=type_str:place%20AND%20label:" + urllib.quote(item["shortname"])+"&wt=json"
        certain += 20
    else:
        url = SOLR_baseurl + "?q=" + urllib.quote(item["shortname"])+"&wt=json"

    response = simplejson.loads(urllib.urlopen(url).read().decode('utf-8'))

    if response['response']['numFound'] > 0:
        if item["type"] == "person":
            print(response['response']['docs'][0]['label'])
            print(item)
            print(url)
        if item["type"] == "place":
            for dbp in response['response']['docs']:
                if item["shortname"].lower() == dbp["label"][0].lower():
                    certain += 20
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
        pprint(item)

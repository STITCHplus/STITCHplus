#!/usr/bin/env python


from xml.etree.ElementTree import Element
from xml.etree import ElementTree as etree
from xml.etree.ElementTree import SubElement

import simplejson, urllib
from pprint import pprint

import os,re


SOLR_baseurl = "http://localhost:8080/solr/dbpedia/select"

data = "kb_thesauri" + os.sep + "thesauri_data_example.xml"

fh = open (data, 'r')
xml_data = etree.fromstring(fh.read())
fh.close()

xml_data = xml_data.find('{http://www.openarchives.org/OAI/2.0/}ListRecords')

count = 0 
place_count = 0
person_count = 0

records = []

for item in xml_data:
    if item.find('{http://www.openarchives.org/OAI/2.0/}metadata'):
        type = False
        count += 1
        for name in item.find('{http://www.openarchives.org/OAI/2.0/}metadata').getiterator():
            if name.tag.endswith('identifier'):
                nid = name.text
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
                name = unicode(name.text).encode('utf-8').strip()
                shortname = name.split('(')[0].strip()

                dobfind = name.replace(shortname, '')
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

                record = {"name" : name, "shortname" : shortname, "type" : type }

                if len(yob) > 0:
                    record['yob'] = yob
                if len(yod) > 0:
                    record['yod'] = yod

                records.append(record)

for item in records:
    url = SOLR_baseurl + "?q=label:" + urllib.quote(item["shortname"])+"&wt=json"
    data = simplejson.loads(urllib.urlopen(url).read().decode('utf-8'))
    print(data)

    #print(response["response"]["numFound"])

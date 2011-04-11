#!/usr/bin/env python


from xml.etree.ElementTree import Element
from xml.etree import ElementTree as etree
from xml.etree.ElementTree import SubElement

import simplejson, urllib

import os



data = "kb_thesauri" + os.sep + "thesauri_data_example.xml"

fh = open (data, 'r')
xml_data = etree.fromstring(fh.read())
fh.close()

xml_data = xml_data.find('{http://www.openarchives.org/OAI/2.0/}ListRecords')


for item in xml_data:
    if item.find('{http://www.openarchives.org/OAI/2.0/}metadata'):
        type = False
        for name in item.find('{http://www.openarchives.org/OAI/2.0/}metadata').getiterator():
            if name.tag.endswith('identifier'):
                nid = name.text
            if name.tag.endswith('inScheme'):
                for i in name.attrib.values():
                    if i.find('geografisch') > -1:
                        type='place'
                        break
            if name.tag.endswith('type'):
                if name.text == "persoon" or name.text == 'person':
                    type = "person"

            if name.tag.endswith('prefLabel'):
                if 'nl' in name.attrib.values():
                    fullabel = unicode(name.text).encode('utf-8')
                    preflabel = fullabel.split('(')[0].strip()
                    if type == "person":
                        url = 'http://tomcat1.kbresearch.nl/solr/dbpedia/select/?q=label:'+urllib.quote(preflabel)+'%20AND%20type_str:person&wt=json&rows=1&fl=label_str,id'
                    elif type == 'place':
                        url = 'http://tomcat1.kbresearch.nl/solr/dbpedia/select/?q=label:'+urllib.quote(preflabel)+'%20AND%20type_str:place&wt=json&rows=1&fl=label_str,id'
                    else:
                        url = 'http://tomcat1.kbresearch.nl/solr/dbpedia/select/?q=label:'+urllib.quote(preflabel)+'&wt=json&rows=1&fl=label_str,id'

                    data = simplejson.loads(urllib.urlopen(url).read())

                    if data['response']['numFound'] > 1:
                        if data['response']['docs'][0]['label_str'][0].split('(')[0] == preflabel:
                            for i in item.find('{http://www.openarchives.org/OAI/2.0/}header'):
                                if i.tag.endswith('identifier'):
                                    print(i.text + ' =~ ' + data['response']['docs'][0]['id'])

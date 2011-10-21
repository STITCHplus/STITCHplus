#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
    Copyright (c) 2011 KB, Koninklijke Bibliotheek.

    This file is part of the STITCHplus project.
    (http://www.catchplus.nl/en/diensten/deelprojecten/stitchplus/)

    DBpedia_to_solr.py is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    DBpedia_to_solr.py is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBpedia_to_solr.py. If not, see <http://www.gnu.org/licenses/>.
"""

#
# DBpedia2solr example script.
#

import dbpedia

import os

from xml.etree.ElementTree import Element
from xml.etree import ElementTree as etree
from xml.etree.ElementTree import SubElement

import http.client

import urllib.error
import urllib.parse
import urllib.request

__author__ = "Willem Jan Faber"
__licence__ = "GPL"

SOLR_url = "/solr/dbpedia/update/"
SOLR_base = "localhost:8080"

def post_xml_to_solr(xml):
    """
        post xml to solr
    """

    done = False
    headers = {"Content-type" : "text/xml; charset=utf-8", "Accept": "text/plain"}

    try:
        conn = http.client.HTTPConnection(SOLR_base)
        conn.request("POST", SOLR_url, bytes(xml.encode('utf-8')), headers)
        response = conn.getresponse()
    except:
        return(False)
    if response.getcode() == 200:
        res = response.read()
        if not str(res).find("<int name=\"status\">0</int>") > -1:
            print(res)
            return(False)
        else:
            return(True)
    conn.close()
    return(False)


if __name__ == "__main__":
    dbp = dbpedia.DBpedia(prefLang='nl')
    dbp.DEBUG=1
    resource = dbp.next()
    i=0
    total=""

    while resource:

        doc = Element("add")
        add = SubElement(doc, "doc")

        sub = SubElement(add, 'field', {"name" : "id" })
        sub.text = dbp.resource_id
       
        # Try to fetch the label from data.dbpedia.org, or fallback to label from file.
        if dbp.extract('label'):
            label = dbp.extract('label')
        else:
            label = dbp.resource_id.split('/')[-1]

        sub = SubElement(add, 'field', {"name" : "label" })
        sub.text = label
        sub = SubElement(add, 'field', {"name" : "label_str" })
        sub.text = label

        rtype = "misc" # Default type of record. 

        for name in dbp.dbpedia_label.keys():
            if dbp.extract(name):
                if not name == 'label':
                    if name == 'comment' and ( dbp.extract('abstract') == dbp.extract(name) ):
                        pass
                    else:
                        sub = SubElement(add, 'field', {"name" : name })
                        sub.text = dbp.extract(name)

                        if name == "dbpedia_type" and sub.text.find('Scientist') > -1: rtype = "person"
                        if name == "dbpedia_type" and sub.text.find('Politician') > -1: rtype = "person"
                        if name == "dbpedia_type" and sub.text.find('Person') > -1: rtype = "person"
                        if name == "dbpedia_type" and sub.text.find('Place') > -1: rtype = "place"
                        if name == "dbpedia_type" and sub.text.find('PopulatedPlace') > -1: rtype = "place"
                        if name == "dbpedia_type" and sub.text.find('Country') > -1: rtype = "place"
                        if name == "dbpedia_type" and sub.text.find('Organisation') > -1: rtype = "organisation"

                        sub = SubElement(add, 'field', {"name" : name+"_str" })
                        sub.text = dbp.extract(name)

                if name == 'geopoint':
                    rtype = "place"

                if name == "yob":
                    rtype = "person"
                    if len(dbp.extract(name)) == len('1929-01-01T00:00:00-05:00'):  #Convert DBpedia date to solr datetype
                        sub = SubElement(add, 'field', {"name" : "yob_date" })
                        sub.text = "-".join(dbp.extract(name).split('-')[:-1])+"Z"

                if name == "yod":
                    rtype = "person"
                    if len(dbp.extract(name)) == len('1929-01-01T00:00:00-05:00'):  
                        sub = SubElement(add, 'field', {"name" : "yod_date" })
                        sub.text = "-".join(dbp.extract(name).split('-')[:-1])+"Z"

                if name == 'dob':
                    rtype = "person"
                    if len(dbp.extract(name)) == len('1500-02-24'): 
                        s=dbp.extract(name)
                        if (s[8:10]+s[5:7]+s[:4]).isdigit():
                            sub = SubElement(add, 'field', {"name" : "dob_date" })
                            sub.text = dbp.extract(name)+"T00:00:00Z"

                if name == 'dod':
                    rtype = "person"
                    if len(dbp.extract(name)) == len('1500-02-24'):  
                        s=dbp.extract(name)
                        if (s[8:10]+s[5:7]+s[:4]).isdigit():
                            sub = SubElement(add, 'field', {"name" : "dod_date" })
                            sub.text = dbp.extract(name)+"T00:00:00Z"

        sub = SubElement(add, 'field', {"name" : "type_str"})
        sub.text = rtype

        i+=1
        if i>51461:
            if post_xml_to_solr(etree.tostring(doc)):
                print("ADD" , i, label)
        else:
            print(i, label)

        resource = dbp.next()
        

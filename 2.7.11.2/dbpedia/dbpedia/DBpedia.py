#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
    Copyright (c) 2011 KB, Koninklijke Bibliotheek.

    This file is part of the STITCHplus CATCHplus project.
    (http://www.catchplus.nl/en/diensten/deelprojecten/stitchplus/)

    DBpedia.py is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    DBpedia.py is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBpedia.py. If not, see <http://www.gnu.org/licenses/>.
"""

import os
import bz2
import sys
import time
import json

import http.client

import urllib.error
import urllib.parse
import urllib.request

from xml.etree import ElementTree as etree
from xml.etree.ElementTree import SubElement
from xml.etree.ElementTree import Element

__author__ = "Willem Jan Faber"
__licence__ = "GPL"

class DBpedia(object):
    """

    DBpedia downloads the label.bz2 file from http://downloads.dbpedia.org/ if necessary,
    by default it will open and parse the file, it uses an itterator to traverse.

    usage :

    >>> dbpedia = DBpedia('nl')
    >>> dbpedia.next()
    >>> dbpedia.extract('label')
    >>> dbpedia.extract('comment')

    """

    lang = "nl" # Prefered language
    CACHE_DIR = '/tmp' # Location to put bz2 label file.

    DBPEDIA_url = "http://downloads.dbpedia.org/3.6/"+lang+"/" # Location where the DBpedia bz files are hosted.
    DBPEDIA_filename = "labels_"+lang+".nt.bz2"

    DEBUG = 1

    AUTOGET = True # Auto fetch objects from data.dbpedia.org
 
    dbpedia_label = {'label' : 'http://www.w3.org/2000/01/rdf-schema#label',
                     'abstract' : 'http://dbpedia.org/ontology/abstract',
                     'comment' : 'http://www.w3.org/2000/01/rdf-schema#comment', 
                     'dob' :   'http://dbpedia.org/ontology/birthDate',
                     'yob' :   'http://dbpedia.org/ontology/birthYear',
                     'redirect' : 'http://dbpedia.org/ontology/wikiPageRedirects',
                     'sameas' : 'http://www.w3.org/2002/07/owl#sameAs',
                     'geopoint' : 'http://www.w3.org/2003/01/geo/wgs84_pos#geometry',
                     'mayor' : 'http://dbpedia.org/property/mayor',
                     'relatedlinks' : 'http://dbpedia.org/ontology/wikiPageExternalLink' ,
                     'homepage' : 'http://xmlns.com/foaf/0.1/homepage',
                     'surname' : 'http://xmlns.com/foaf/0.1/surname',
                     'thumbnail' : 'http://dbpedia.org/ontology/thumbnail',
                     'shortdescription' : 'http://dbpedia.org/property/shortDescription',
                     'depiction' : 'http://xmlns.com/foaf/0.1/depiction',
                     'givenname' : 'http://xmlns.com/foaf/0.1/givenName',
                     'nationality' : 'http://dbpedia.org/property/nationality',
                     'dod' : 'http://dbpedia.org/ontology/deathDate',
                     'yod' : 'http://dbpedia.org/ontology/deathYear',
                     'deathcause' : 'http://dbpedia.org/property/deathCause',
                     'dbpedia_type' : 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
                     'deathplace' : 'http://dbpedia.org/property/deathPlace',
                     'website' : 'http://dbpedia.org/property/website',
                     'recidence' : 'http://dbpedia.org/ontology/residence' } 

    def __init__(self, prefLang = 'nl'):
        """
            Open or Download and open the label.bz file from DBpedia.
            'fh' contains the open file handle.
        """
        if not prefLang == self.lang:
            self.lang= prefLang
        self.DBPEDIA_filename = "labels_"+self.lang+".nt.bz2"
        self.DBPEDIA_url = "http://downloads.dbpedia.org/3.6/"+self.lang+"/"

        if not os.path.isfile(self.CACHE_DIR+os.sep+self.DBPEDIA_filename):
            if self.DEBUG > 0:
                sys.stdout.write("Could not open " + self.CACHE_DIR + os.sep + self.DBPEDIA_filename+ "\n")
            if not self.download_labels():
                sys.stderr.write("Error while downloading labels.\n")
                os._exit(-1)
        self.fh = bz2.BZ2File(self.CACHE_DIR + os.sep + self.DBPEDIA_filename)


    def __iter__(self):
        return(self)

    def next(self):
        """
            Get next DBpedia label, and download the corresponding object,
            and return the name of the DBpedia object.
        """
        try:
            self.resource=self.fh.readline().decode('iso-8859-1').strip()
        except EOFError as error:
            print(error)

        if self.AUTOGET:
            self.get_resource()
        return(self.resource)

    def get_resource(self, pref_type="ntriples"):
        """
            The DBpedia resource can take on different forms, 
            it is either in 'json', 'jsod' or 'ntriples' format.

            The different formats require different kind of parsing.
            'dbpedia_data_type' is used to store the format information.
            'dbpedia_data' contains the raw data.

            If a type is not available or parsable, another format will be fetched.
            The following order is used : 'ntriples', 'json', 'jsod'.

        """
        self.resource_id = urllib.parse.unquote(self.resource.split('>')[0][1:])
        self.dbpedia_data_type = pref_type
        if self.dbpedia_data_type == "json":
            self.dbpedia_data_type = pref_type
            url = self.resource.split('>')[0][1:].replace('resource', 'data')+ "." + self.dbpedia_data_type
            result = self.get_data(url)
            if not result: 
                self.dbpedia_data_type = "jsod"
            else:
                return(result)
        if self.dbpedia_data_type == "ntriples":
            url = self.resource.split('>')[0][1:].replace('resource', 'data')+ "." + self.dbpedia_data_type
            result = self.get_data(url)
            if not result:
                self.dbpedia_data_type = "json"
            else:
                return(result)
        if self.dbpedia_data_type == "jsod":
            url = self.resource.split('>')[0][1:].replace('resource', 'data')+ "." + self.dbpedia_data_type
            result = self.get_data(url)
            return(result)

    def get_data(self, url):
        """
            Fetch data from given url, and store it in 'dbpedia_data' and return True.
            In case of failure return False.
        """
        self.dbpedia_data = ""
        try:
            dh = urllib.request.urlopen(url)
        except:
            return(False)
        if dh.getcode() == 200:
            try:
                self.dbpedia_data=dh.read().decode('iso-8859-1')
                #.decode('iso-8859-1')
                if self.dbpedia_data.find('# Empty TURTLE') > -1:
                    return(False)
                return(True)
            except:
                return(False)
        else:
            print("Error")
            print(dh.getcode())
        return(False)

    def extract(self, labelname):
        """
            Extract the wanted label from the DBpedia object, and return the value.
            Since there are different forms of DBpedia objects, there are several parsers.
        """
        if not labelname in self.dbpedia_label.keys():
            return(False)

        # Json parser
        if self.dbpedia_data_type == "json":
            try:
                data = json.loads(self.dbpedia_data)
            except:
                return(False)
            
            for item in data.values():
                if self.dbpedia_label[labelname] in item.keys():
                    for val in item[self.dbpedia_label[labelname]]:
                        if 'lang' in val.keys():
                            if val['lang'] == self.lang:
                                return(val['value'])
                            for val in item[self.dbpedia_label[labelname]]:
                                if 'lang' in val.keys():
                                    if val['lang'] == self.lang:
                                        return(val['value'])
                        if 'value' in val.keys():
                            return(val['value'])

        # Ntriples parser
        if self.dbpedia_data_type == "ntriples":
            # First try to get the information in the prefLang
            result = False
            for item in self.dbpedia_data.split('\n'):
                if len(item) > 0:
                    if item.find('"@'+self.lang) > -1:
                        if item.split('\t')[1] == "<" + self.dbpedia_label[labelname] + ">":
                            try:
                                return(bytes(item.split('\t')[2].split('"')[1], 'ascii').decode('unicode-escape'))
                            except:
                                return(item.split('\t')[2].split('"')[1])
            # Fallback if there is no lang available.
            for item in self.dbpedia_data.split('\n'):
                if len(item.strip()) > 0:
                    if len(item.split('\t')) >1:
                        if item.split('\t')[1] == "<" + self.dbpedia_label[labelname] + ">":
                            if item.split('\t')[2].find('"') > -1:
                                return(item.split('\t')[2].split('"')[1])
                            elif item.split('\t')[2].find('>') > -1:
                                try:
                                    return(bytes(item.split('\t')[2].split('>')[0].split('<')[1], 'ascii').decode('unicode-escape')) 
                                    # UNICODE escape convert Belgi\u00EB to België
                                except:
                                    return(item.split('\t')[2].split('>')[0].split('<')[1])
        # Jsod parser
        if self.dbpedia_data_type == "jsod":
            try:
                data = json.loads(self.dbpedia_data)
            except:
                return(False)
            for item in data.values():
                if self.dbpedia_label[labelname] in item.keys():
                    if 'results' in item.keys():
                        for name in item['results']:
                            if self.dbpedia_label[labelname] in name.keys():
                                value=name[self.dbpedia_label[labelname]]
                                if type(value) == type(""):
                                    return(value)
                                if type(value) == type({}):
                                    if '__deferred' in value.keys():
                                        return(value['__deferred']['uri'])

    def download_labels(self):
        """
            Fetches .bz2 label file from the DBpedia download site.
            (http://downloads.dbpedia.org/) and put it in the CACHE_DIR path.
        """
        if self.DEBUG > 0:
            sys.stdout.write("Downloading labels from " + self.DBPEDIA_url+ "\n")
        fh=open(self.CACHE_DIR + os.sep + self.DBPEDIA_filename, "wb")
        try:
            data=urllib.request.urlopen(self.DBPEDIA_url+self.DBPEDIA_filename).read()
        except:
            if self.DEBUG > 0:
                sys.stdout.write("Unable to read data from " + self.DBPEDIA_url+"\n")
            return(False)
        fh.write(data)
        fh.close()
        try:
            fh=bz2.BZ2File(self.CACHE_DIR + os.sep + self.DBPEDIA_filename)
            data=fh.readline()
            fh.close()
        except:
            sys.stderr.write("Unable to read from " + DBPEDIA_filename + ", file is corrupt, remove the file and try again.\n")
            return(False)
        sys.stdout.write("Downloading finished file stored ("+ self.CACHE_DIR + os.sep + self.DBPEDIA_filename+")\n")
        return(True)

if __name__ == "__main__":
    import random
    dbpedia = DBpedia()
    for i in range(int(random.random()*1000)):
        dbpedia.AUTOGET=False
        resource = dbpedia.next()
    dbpedia.AUTOGET=True
    resource = dbpedia.next()
    print(i , resource)
    for label in dbpedia.dbpedia_label.keys():
        res = dbpedia.extract(label)
        if res:
            print(label+'\t\t: ' + res)
    

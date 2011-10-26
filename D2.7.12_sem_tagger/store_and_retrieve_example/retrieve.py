#!/usr/bin/env python

#    retrieve.py: Retrieve from mongodb.
#    For details see: http://opendatachallenge.kbresearch.nl/
#    Copyright (C) 2011 Willem Jan Faber, Koninklijke Bibliotheek - National Library of the Netherlands
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


import cgi
import ast
import urllib, simplejson
from pprint import pprint
from pymongo import Connection

form = cgi.FieldStorage()
od = form.getvalue("od")
url = form.getvalue("url")
callback = form.getvalue("callback")

conn = Connection("192.87.165.3")

def isvalid_url(url):
    return(True)

def isvalid_od(url):
    return(True)

def retrieve():
    if od or url:
        c=conn["opendatachallenge"]["data"]
        docs={}
        if url:
            for item in c.find({"url" : url}):
                docs[item["od"]] = {"label" : item["label"]}
            if callback:
              print callback + "("
            print(simplejson.dumps(docs))
            if callback:
              print ");"
            return()

    if not od:
        print("Missing parameter url")
    if not url:
        print("Missing parameter od")
    return()

print "Content-Type: text; charset=utf-8\n\n"
retrieve()


#data.encode("utf-8", "xmlcharrefreplace"

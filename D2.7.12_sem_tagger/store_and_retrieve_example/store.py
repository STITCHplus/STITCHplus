#!/usr/bin/env python

#    store.py: Store data in mongoDB.
#    For details see: http://opendatachallenge.kbresearch.nl/
#    Copyright (C) 2011  R. van der Ark, Koninklijke Bibliotheek - National Library of the Netherlands
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
label = form.getvalue("label")

conn = Connection("192.87.165.3")

def isvalid_url(url):
    return(True)

def isvalid_od(url):
    return(True)

def store():
    if not od:
        print("Missing parameter url")
        return()
    if not url:
        print("Missing parameter od")
        return()
    if od and url:
        if len(od) > 1000 or len(url) > 1000:
            return()
        if not (od.startswith('VIAF:') or od.startswith('DBP:') or od.startswith('GEO:')):
            return()

        c=conn["opendatachallenge"]["data"]
        for item in c.find({"url" : url}):
            if item["od"] == od:
                print("Link allready made")
                c.disconnect()
                return()

        doc={"url" : url, "od" : od, "label" : label}
        c.save(doc)
        print("Saved")
        c.disconnect()
        return()
    return()

print "Content-Type: text; charset=utf-8\n\n"

store()

#data.encode("utf-8", "xmlcharrefreplace"

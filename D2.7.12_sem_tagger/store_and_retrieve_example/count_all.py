#!/usr/bin/env python

#    count_all.py: Show the number of tags on a page.
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

import os
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
    remote = os.environ['HTTP_REFERER']
    if remote:
        url=remote

    if url:
        c=conn["opendatachallenge"]["data"]
        print("<a style='text-decoration: none;' border=0 target='_top' href='http://dynamic.opendatachallenge.kbresearch.nl/?url="+url+"'><div> <img border=0 src='http://opendatachallenge.kbresearch.nl/tagall_small.png'> This url was tagged "+str(c.find({"url" : url}).count())+" times </div></a>")

    if od:
        c=conn["opendatachallenge"]["data"]
        print("This concept is linked to "+str(c.find({"od" : od}).count())+" uris")

print "Content-Type: text/html; charset=utf-8\n\n"
store()



'''

#data.encode("utf-8", "xmlcharrefreplace"
# convert -font helvetica -fill white -pointsize 36 \
-draw 'text 10,50 "Floriade 2002, Canberra, Australia"' \
floriade.jpg comment.jpg 


'''

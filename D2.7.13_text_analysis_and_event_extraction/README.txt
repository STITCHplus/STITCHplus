Deliverable 2.7.13 Named Entity Recognition (NER) and event extraction
----

This repos contains multiple tools/pieces of experimental software in different stages of maturity.

annie_wrapper - experimental, reusable: a simple wrapper for the annie ner service demo
OpenNLPServlet - mature, reusable: a comprehensive service using the OpenNLP toolkit for NER
simple_lucene_classifier - experimental, needs adaptation: classifier for records using just lucene term vector functions
naiveNE - experimental, reusable: very simple NER: just look at tokens starting with upper case; used for benchmarking
event_recognition - experimental, needs adaptation: recognize events using NER via url and proximity in text

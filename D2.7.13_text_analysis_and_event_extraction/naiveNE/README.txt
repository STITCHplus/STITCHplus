NaiveNE
---

Recognizes named entities via URL, solely by looking at tokens starting with upper-case.

Very useful as a benchmark to test professional NER-software against. Also supports alto-xml

The gist: high recall, low precision.

Dependencies:
ruby1.8
gems:
sinatra >= 1.1.2
hpricot >= 0.8.2

Note:
naiveNE.rb can also be used for standalone command-line purposes

Simple command line classifier-tool using lucene.

Uses the content of a small sample set of tagged records to define a list of most relevant terms (using lucene tf_idf scoring mechanism + search and retrieval) per class.

The tag_data.json file contrains three concept classes, connected to the ANP press OCR data:
- Cold War
- China
- Hunger

dependencies:
ruby1.8
gems:
json >= 1.46

Sample output:


DBP:Hunger
hongersnood: 268 -- 0.001686
honger: 228 -- 0.001112
voedsel: 199 -- 0.000197
droogte: 167 -- 0.000771
heerst: 110 -- 0.000319
landbouworganisatie: 86 -- 0.001452
lijden: 80 -- 0.000326
bedreigd: 76 -- 0.000228
india: 62 -- 0.000108
graan: 54 -- 0.000707
sturen: 50 -- 0.000134
voedselhulp: 46 -- 0.002298
oogst: 45 -- 0.000625
kruis: 45 -- 0.000191
ethiopie: 37 -- 0.000521
langdurige: 33 -- 0.000346

GEO:1814991 (China)
communistisch: 274 -- 0.000133
sjanghai: 208 -- 0.001653
peking: 141 -- 0.000135
nationalistische: 130 -- 0.000310
formosa: 125 -- 0.000618
nationalistisch: 122 -- 0.000626
communisten: 112 -- 0.000132
communistischchina: 82 -- 0.001098
hongkong: 82 -- 0.000662
nationalisten: 67 -- 0.000427
nanking: 54 -- 0.003112
echter: 48 -- 0.000130
japansche: 47 -- 0.003936
wateren: 46 -- 0.000292
territoriale: 44 -- 0.000507
copie: 39 -- 0.000395

DBP:Cold_War
oostduitse: 319 -- 0.000142
berlijn: 283 -- 0.000122
westberlijn: 171 -- 0.000241
koude: 125 -- 0.000761
oostduitsland: 125 -- 0.000165
oostberlijn: 94 -- 0.000415
berlijnse: 93 -- 0.000683
bondskanselier: 91 -- 0.000126
westberlijnse: 88 -- 0.000774
adenauer: 52 -- 0.000349
oostduitsers: 51 -- 0.000634
brandt: 51 -- 0.000427
grenswachten: 49 -- 0.001001
mogendheden: 49 -- 0.000196
russen: 39 -- 0.000118
warschau: 38 -- 0.000163

Deliverable D2.7.9: Harvesting mechanisme.

De SKOS thesaurus van de KB kan worden geharvest via het OAI protocol vanaf de URL:
http://kbresearch.nl/general/thesaurus_harvest/

Naast de standaard OAI parameters kan er gebruik gemaakt worden van de parameter 'enrich=true'. Deze voegt automatisch gegenereerde linked data verwijzingen in in de response, als skos:closeMatch. Dit is uiteraard expirimenteel, dus voor betrouwbare informatie wordt aangeraden deze parameter niet mee te geven.

Zo gauw de thesaurus formeel in productie staat zal er de definitieve endpoint worden gebruikt.

HARVESTER BRONCODE:
Bijgeleverd zijn twee harvesters.
- Voorgeconfigureerde Java harvester voor stabiele en regelmatige harvests.
- Ruby harvester om snel inzicht te krijgen in de data in de endpoint

Voor meer informatie verwijs ik naar de bijgevoegde quick start guides.

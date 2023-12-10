# Project-LFDS - Proof-of-concept geautomatiseerde data workflow.

## 1.1. Verzamelen ruwe tijdseriedata

Hiervoor gebruik ik het script [scraping.sh](scripts/scraping.sh). Ik verzamel ruwe tijdseriedata van [de iRail API](https://docs.irail.be/#top), die allerhande informatie bevat over het belgische treinnetwerk. Stations, liveboards, vehicles en disturbances kunnen hieraan opgevraagd worden. Ik heb ervoor gekozen met liveboards en stations te zerken. Voor elk station dat beschikbaar is via de API, vraag ik het huidige liveboard op en dit sla ik op in een xml bestand in een "scrapes" folder.

Overzicht van verwachte en geimplementeerde functionaliteit:
- [x] voldoende gecompliceerde data
  - dit is in orde aangezien liveboards gecompliceerd is, en ik daarnaast een minder gecompliceerde dataset stations gebruik
- [ ] Het script neemt geen argumenten
- [ ] produceert geen uitvoer op stdout of stderr 
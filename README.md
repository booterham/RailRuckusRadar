# Project-LFDS - Proof-of-concept geautomatiseerde data workflow

## 1.2 - Verzamelen ruwe tijdseriedata

Hiervoor gebruik ik het script [scraping.sh](scripts/scraping.sh). Ik verzamel ruwe tijdseriedata van [de iRail API](https://docs.irail.be/#top), die allerhande informatie bevat over het belgische treinnetwerk. Stations, liveboards, vehicles en disturbances kunnen hieraan opgevraagd worden. Ik heb ervoor gekozen met liveboards en stations te zerken. Voor elk station dat beschikbaar is via de API, vraag ik het huidige liveboard op en dit sla ik op in een xml bestand in een "scrapes" folder.

### Overzicht van verwachte en geimplementeerde functionaliteit voor scraping

- [x] voldoende gecompliceerde data
  - dit is in orde aangezien liveboards gecompliceerd is, en ik daarnaast een minder gecompliceerde dataset stations gebruik
- [x] Het script neemt geen argumenten
- [x] Het script produceert geen uitvoer op stdout of stderr
- [x] De directory voor de gescrapete data is instelbaar ahv een variabele
- [ ] Eventuele informatieve boodschappen over het verloop van de download, foutboodschappen, enz. worden opgeslagen in een logbestand.
- [ ] het script wordt op regelmatige tijdstippen uitgevoerd adhv cron
- [x] Het resultaat van dit proces zal een directory zijn met vele bestanden in JSON, HTML, XML of een ander tekstgebaseerd bestandsformaat.
- [x]  ruwe data nooit gewijzigd mag worden
  - [x] ruwe data is read-only

## 1.2 - Data transformeren

Hiervoor gebruik ik het script [transforming.sh](scripts/transforming.sh). Dit script checkt of er reeds een transformatie van de data bestaat. Indien wel, dan wordt alles verwijderd en wordt opnieuw begonnen. Per bestand in de `scrapes` folder, wordt de inhoud in een temporary file uitgelezen. Daarna worden alle 404 errors verwijderd a.d.h.v. een regex. Verder wordt info uit een liveboard gesplitst in info over het station en info over de vertrekkende trein. Daarna wordt deze info samengevoegd om zo per vertrekkende trein heel wat info te krijgen over vertrek, aankomst, vertraging, etc. Deze data wordt opgeslagen in `transformed.csv`. Voor deze bewerkingen, werk ik grotendeels met het [sed](https://www.gnu.org/software/sed/manual/sed.html) commando. Dit aangezien er veel data is, en sed zeer snel is.

### Overzicht van verwachte en geimplementeerde functionaliteit voor transforming

- [x] Het script loopt over alle bestanden uit eerste script verkregen.
- [x] Het script houdt enkel nuttige informatie bij.
- [x] Het resultaat is 1 CSL-bestand.
- [x] Het CSV-bestand heeft een hoofding met namen van alle variabelen.
- [x] Elke observatie vormt een aparte regel.
- [ ] Soms te maken hebt met ontbrekende of corrupte data.

## 1.3 - Data analyseren



# Freifunk Advanced Buildroot

## Mithelfen

### Entwickeln
Wir suchen immer Freiwillige. Eine Liste von Aufgaben die noch ausstehen
oder in Bearbeitung sind findest du im [Issue-Tracker auf Github](https://github.com/FreifunkAdvanced/ff-advanced/issues)

Bei Interesse forke das Haupt-Repository in dein eigenes Repository und wenn
du fertig bist, mache einen Pull Request um die Änderungen in das Haupt-Repo
einfließen zu lassen.

Wenn du mehrere features/bugs bearbeiten willst, erstelle bitte jeweils einen
eigenen branch und damit eigene Pull Requests. Dies hilft uns beim bearbeiten
und organisieren der Pull Requests.

#### Buildroot bauen
Das Buildsystem lädt OpenWrt automatisch herunter, nimmt vorkonfigurierte
Anpassungen vor (Konfigurationsdateien, Paketwahl etc.) und erzeugt dann die
Firmwareimages und Pakete.

Will man alle Firmwareimages kompilieren, trägt man in der settings.mk.example
seinen Namen und seine Mailadresse ein, speichert sie als settings.mk  und kann 
dann mit make dem Buildvorgang starten. make help gibt die Hilfe für den 
Buildvorgang aus.

Weitere Dokumentation befindet sich im doc-Verzeichnis, u.a. das build-Howto,
Informationen zum Erstellen einer neuen Funkzelle und diverses.

Bei Detailfragen am besten an die Dev Mailingliste wenden, siehe
https://mailman.freifunk-rheinland.net/cgi-bin/mailman/listinfo

### Bugs sammeln
Du hast ein Fehler gefunden? Bitte schaue in den [Issue-Tracker](https://github.com/FreifunkAdvanced/ff-advanced/issues)
und vergewissere dich, dass das Problem noch nicht gemeldet wurde. Falls es
schon gemeldet wurde, kannst du dich gerne an der Diskussion beteiligen und
mit Details aushelfen.

Wenn ein Problem noch nicht gemeldet wurde, bitte melde es, und liefere dort
folgende Infos, falls möglich/bekannt:
- Im Titel eine kurze aber präzise Zusammenfassung des Problems
- Die Modellnummer des Routers
- Die Hardware Revision d. Routers (steht auf der Rückseite d. Routers)
- Die Firmware Version die installiert ist
- Die Funkzelle des Routers (Düsseldorf, Neuss etc)
- Was ist passiert?
- Was hätte passieren sollen?
- Ist es reproduzierbar? Wenn ja, wie?

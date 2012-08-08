ffrheinland-buildroot
=====================

Dies ist ein automatisches Buildsystem des Freifunk Rheinland e.V. für OpenWrt,
mit dem sich für die FFRL-Funkzellen angepasste Router-Firmware erstellen lässt.

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

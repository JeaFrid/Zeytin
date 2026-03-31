# Zeytin <🫒/>

**Zeytin** ist eine hochleistungsfähige, skalierbare und sicherheitsorientierte Serverlösung der nächsten Generation, die Abhängigkeiten von externen Datenbanken eliminiert. Durch die Nutzung der Leistungsfähigkeit der Sprache Dart fungiert es sowohl als Webserver als auch als benutzerdefinierte NoSQL-Datenbank-Engine.

In herkömmlichen Backend-Architekturen existieren Server und Datenbank als getrennte Schichten, was zu Netzwerklatenzen und Verwaltungsaufwand führt. Zeytin durchbricht diese Barrieren, indem es die Datenbank-Engine direkt in den Speicher und die Verarbeitungsprozesse des Servers einbettet.

## Warum Zeytin?

Es bietet eine einfache, aber leistungsstarke Antwort auf die komplexen Infrastrukturprobleme, die bei der modernen Anwendungsentwicklung auftreten.

### 1. Autark

Bei der Verwendung von Zeytin müssen keine externen Dienste wie MongoDB, PostgreSQL oder Redis installiert, konfiguriert oder verwaltet werden. Im Inneren von Zeytin befindet sich eine spezielle festplattenbasierte und ACID-konforme Datenbank-Engine, die wir **Truck** nennen. Sobald Sie die Installation abgeschlossen haben, ist Ihre Datenbank bereit.

### 2. Isolationsarchitektur und Hochleistung

Das System basiert auf der **Isolate**-Technologie von Dart. Jede Benutzerdatenbank (Truck) läuft in einem Thread, der unabhängig und vom Hauptserver isoliert ist. Dies stellt sicher, dass umfangreiche Datenschreibvorgänge eines Benutzers den Server niemals daran hindern, anderen Benutzern zu antworten. Dank des speziellen **Binary Encoder** benötigen Daten viel weniger Platz als im JSON-Format und werden wesentlich schneller verarbeitet.

### 3. Interne Firewall: Gatekeeper

Zeytin überlässt in puncto Sicherheit nichts dem Zufall. Es analysiert den Serververkehr kontinuierlich mit dem **Gatekeeper**-Modul:

- Wechselt bei sofortigen Lastspitzen automatisch in den Ruhemodus (Sleep Mode).
- Blockiert Spam-Anfragen durch Anwendung von IP-basierter Ratenbegrenzung.
- Erkennt böswillige Versuche und sperrt die entsprechenden IP-Adressen.

### 4. Ende-zu-Ende-Verschlüsselung

Ihre Daten sind nicht nur auf der Festplatte sicher, sondern auch während der Übertragung über das Netzwerk. Zeytin verschlüsselt den kritischen Datenverkehr zwischen Client und Server unter Verwendung des **AES-CBC**-Standards mit Schlüsseln, die aus dem Passwort des Benutzers abgeleitet werden. Selbst der Datenbankadministrator kann den Inhalt der Daten nicht sehen, ohne das Benutzerpasswort zu kennen.

### 5. Echtzeit- und Multimedia-Unterstützung

Es speichert nicht nur Daten, sondern bietet auch Live-Funktionen, die für moderne Anwendungen erforderlich sind:

- **Watch:** Sie können Änderungen in der Datenbank sofort über WebSocket verfolgen.
- **Call:** Verwaltet Sprach- und Videoanrufräume dank interner LiveKit-Integration.

---

## Architekturüberblick

Die Datenstruktur von Zeytin ist nach realer Logistiklogik aufgebaut und besteht aus drei Hauptschichten:

- **Truck (LKW):** Die Hauptdatenbankdatei, die jedem Benutzer zugewiesen ist. Sie ist physisch von anderen Benutzern isoliert.
- **Box (Kiste):** Tabellen, die zur Kategorisierung von Daten verwendet werden (z. B. Produkte, Bestellungen).
- **Tag (Etikett):** Der eindeutige Schlüssel, der für den Zugriff auf Daten verwendet wird.

## Schnellinstallation

Ein einziger Befehl reicht aus, um Zeytin auf Ihrem Server zu installieren und alle Abhängigkeiten (Dart, Docker, Nginx, SSL) zu konfigurieren.

### Debian/Ubuntu
```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh && sudo bash install.sh
```

### Fedora/RHEL/CentOS
```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_fedora.sh && sudo bash install.sh
```

### Arch Linux
```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_arch.sh && sudo bash install.sh
```

### macOS
```bash
curl -fsSL https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_macos.sh | bash
```

### Windows (PowerShell als Administrator)
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/platforms/install_windows.ps1" -OutFile "install.ps1"; .\install.ps1
```

# 1. Einführung und Architektur

Zeytin ist viel mehr als eine Standard-Serversoftware. Während es von außen wie ein Backend aussieht, das REST-API-Dienste anbietet, läuft in seinem Herzen eine benutzerdefinierte, festplattenbasierte, hochleistungsfähige NoSQL-Datenbank-Engine, die vollständig in Dart geschrieben ist.

Normalerweise sind Datenbank und Server in modernen Backend-Architekturen getrennte Schichten. In der Zeytin-Struktur gibt es diese Unterscheidung nicht. Die Datenbank-Engine ist direkt in den Server, seinen Speicher und seine Prozesse eingebettet. Dies ermöglicht es ihr, unglaubliche Geschwindigkeiten mit direktem Speicher- und Festplattenzugriff zu erreichen, ohne Netzwerklatenz.

Um die Zeytin-Architektur zu verstehen, müssen Sie die drei grundlegenden Bausteine kennen, aus denen das System besteht: **Truck**, **Box** und **Tag**.

## Datenhierarchie

Die Datenspeicherungslogik des Systems hat eine Hierarchie, die mit dem realen Leben in Verbindung gebracht werden kann. Ganz oben steht Zeytin, das System selbst; darunter befinden sich die Truck-Strukturen, bei denen es sich um isolierte Speichereinheiten handelt; innerhalb dieser Einheiten befinden sich Kategorien, nämlich Box-Bereiche; und schließlich Tag und Value, die die Daten selbst darstellen.

```text
ZEYTIN (Server)
└── TRUCK (Truck / Datenbankdatei)
    ├── BOX (Box / Sammlung)
    │   ├── TAG (Etikett / Schlüssel): VALUE (Wert / Daten)
    │   ├── TAG: VALUE
    │   └── ...
    └── BOX
        └── ...
```

### 1. Truck

Truck ist der größte und wichtigste Baustein der Zeytin-Architektur. Er entspricht dem Konzept einer Datenbank in klassischen Datenbanksystemen. Technisch gesehen repräsentiert er jedoch viel mehr.

Jeder Truck besteht physisch aus zwei Dateien auf der Festplatte:

- **Datendatei (.dat):** Der Ort, an dem Daten in einem komprimierten Binärformat gespeichert werden.
- **Indexdatei (.idx):** Die Karte, die die Positionen der Daten auf der Festplatte enthält, d. h. Offset- und Längeninformationen.

**Isolation und Leistung:**
Zeytin öffnet für jeden erstellten Truck ein separates Isolate, d. h. einen isolierten Verarbeitungsthread, auf dem Prozessor. Dies bedeutet, dass ein schwerer Lese- oder Schreibvorgang, der von Benutzer A auf seinem Truck durchgeführt wird, niemals die Truck-Struktur von Benutzer B verlangsamt oder sperrt. Jeder Truck hat seinen eigenen Speicher, seinen eigenen Cache und seine eigene Verarbeitungswarteschlange.

Wenn ein Benutzerkonto im System erstellt wird, wird diesem Benutzer tatsächlich ein spezieller Truck zugewiesen. Somit sind die Daten der Benutzer physisch und logisch vollständig voneinander getrennt.

### 2. Box

Die logischen Abschnitte, die zur Kategorisierung von Daten innerhalb von Truck-Strukturen verwendet werden, werden Boxen genannt. Dies ähnelt einer Tabelle in SQL-Datenbanken oder einer Collection-Struktur in MongoDB.

Sie können eine unbegrenzte Anzahl von Boxen in einen Truck legen. Beispielsweise könnten sich in einem Truck, der für einen E-Commerce-Benutzer erstellt wurde, folgende Box-Bereiche befinden:

- `products`
- `orders`
- `settings`

Box-Strukturen sind keine physisch separaten Dateien; es sind logische Etiketten innerhalb der Truck-Datei, die angeben, zu welcher Gruppe die Daten gehören. Wenn Sie also in der Box `products` suchen, verschwendet das System keine Zeit mit Daten in der Box `orders`.

### 3. Tag

Dies ist der eindeutige Schlüssel, der für den Zugriff auf Daten verwendet wird. Jedes Datenstück innerhalb einer Box muss einen eigenen eindeutigen Tag-Wert haben. Es funktioniert nach der Logik eines Primärschlüssels in SQL-Strukturen oder des Schlüssels in Key-Value-Systemen.

Wenn die Zeytin-Engine Daten lesen möchte, folgt sie jeweils dem Pfad Truck, Box und Tag. Dank des Indizierungssystems dauert das Auffinden eines Tag-Werts und das Abrufen der Daten nur Millisekunden, unabhängig von der Größe der Datenbank. Dies liegt daran, dass das System nicht die gesamte Datei scannt; es geht direkt zur Festplattenkoordinate des Tag-Werts und liest nur diesen Teil.

---

## Beispielszenario: Datenfluss

Lassen Sie uns anhand eines Beispiels untersuchen, wie das System funktioniert. Nehmen wir an, ein Benutzer möchte Themeninformationen in der Box "Einstellungen" speichern.

1.  **Anfrage geht ein:** Der Benutzer möchte die Daten `{ "mode": "dark" }` mit dem Tag `theme` in die Box `settings` schreiben.
2.  **Routing:** Die Zeytin-Hauptklasse erkennt, mit welchem **Truck**, d. h. mit welcher Identitäts-ID, dieser Benutzer die Operation durchführt.
3.  **Proxy-Kommunikation:** Der Hauptserver schreibt die Daten nicht direkt auf die Festplatte. Stattdessen sendet er über `TruckProxy` eine Nachricht an den isolierten Thread, der speziell für diesen Truck läuft.
4.  **Engine schaltet sich ein:**
    - Der isolierte Prozessor empfängt die Nachricht.
    - Er komprimiert die Daten mit einem speziellen **Binary Encoder** und übersetzt sie in Maschinensprache.
    - Er hängt die Daten ganz am Ende der `.dat`-Datei an.
    - Er speichert den neuen Speicherort der Daten in der Datei in der `.idx`-Datei.
    - Schließlich schreibt er die Daten für den schnellen Zugriff in den **LRU Cache** im Speicher.

Dank dieser Architektur bietet Zeytin gleichzeitig die Beständigkeit eines Dateisystems und die Geschwindigkeit von In-Memory-Datenbanken.

# 2. Installation und Konfiguration

Zeytin ist ein System, das sich tief in die Maschine integriert, auf der es läuft. Es reicht nicht aus, nur eine Codedatei auszuführen; Teile wie der Festplattenzugriff der Datenbank-Engine, die Docker-Verbindung des Medienservers und die Nginx-Konfiguration für die Kommunikation mit der Außenwelt müssen zusammenkommen.

Um diesen komplexen Prozess mit einer einzigen Zeile zu bewältigen, haben wir ein fortschrittliches Automatisierungsskript namens `server/install.sh` vorbereitet. Dieses Skript nimmt Ihren Server von Grund auf und macht ihn vollständig bereit für eine Produktionsumgebung.

## Automatisches Installationsskript

Um die Installation zu starten, führen Sie einfach die Datei `server/install.sh` als autorisierter Benutzer auf Ihrem Server aus. Das Skript ist für Debian- und Ubuntu-basierte Systeme optimiert.

```bash
wget -qO install.sh https://raw.githubusercontent.com/JeaFrid/Zeytin/main/server/install.sh && sudo bash install.sh
```

Wenn Sie diesen Befehl eingeben, folgt das Skript nacheinander diesen Schritten:

### 1. Grundlegende Abhängigkeiten und Dart

Zuerst aktualisiert und installiert das System grundlegende Pakete wie `git`, `curl`, `unzip`, `openssl` und `nginx`. Anschließend prüft es, ob die Sprache Dart auf dem Rechner installiert ist. Falls nicht, fügt es die offiziellen Repositories von Google zum System hinzu und schließt die Installation des Dart SDK ab.

Schließlich wechselt es in das Projektverzeichnis, führt den Befehl `dart pub get` aus und lädt alle in der Datei `pubspec.yaml` angegebenen Bibliotheken (shelf, crypto, encrypt usw.) herunter, wodurch das Projekt bereit zum Kompilieren wird.

### 2. LiveKit und Docker-Integration (Optional)

Das Skript stellt Ihnen folgende Frage:
`Do you want to enable Live Streaming & Calls?`

Wenn Sie **y** (ja) sagen, werden die Medienfunktionen des Systems aktiviert:

- **Docker-Check:** Wenn Docker nicht auf dem Rechner vorhanden ist, wird automatisch die neueste Docker-Version installiert.
- **Container-Einrichtung:** Das erforderliche Docker-Image für den LiveKit-Server wird heruntergeladen und ein Container namens `zeytin-livekit` wird gestartet.
- **Schlüsselgenerierung:** Das Skript verwendet `openssl`, um einen zufälligen und sicheren API-Schlüssel und einen geheimen Schlüssel (Secret Key) zu generieren.
- **Config-Update:** Dies ist der beeindruckendste Teil. Das Skript nimmt diese generierten Schlüssel und die externe IP-Adresse des Servers, öffnet die Datei `lib/config.dart` in Ihrem Quellcode und aktualisiert automatisch die entsprechenden Zeilen. Sie müssen die Datei nicht öffnen und manuell Einstellungen vornehmen.

### 3. Nginx- und SSL-Konfiguration (Optional)

Das Skript stellt Ihnen die zweite kritische Frage:
`Do you want to install and configure Nginx with SSL?`

Diese Stufe dient dazu, Ihre Anwendung sicher für die Außenwelt zu öffnen. Wenn Sie **y** sagen:

- **Domain-Definition:** Es fragt Sie nach einem Domainnamen (z. B. api.beispiel.com) und einer E-Mail-Adresse für SSL-Benachrichtigungen.
- **Reverse Proxy:** Es erstellt eine spezielle Konfigurationsdatei für Nginx. Diese Einstellung fängt Anfragen ab, die an den Ports 80 und 443 eingehen, und leitet sie an den Zeytin-Server weiter, der im Hintergrund auf Port 12852 läuft. Notwendige Header-Einstellungen (Upgrade, Connection), damit WebSocket-Verbindungen nicht abreißen, werden automatisch hinzugefügt.
- **Isolierter Certbot:** Es richtet eine virtuelle Python-Umgebung (venv) unter `/opt/certbot` ein, um die Python-Bibliotheken Ihres Systems nicht zu beeinträchtigen. Es installiert Certbot in diesem isolierten Bereich.
- **SSL-Zertifikat:** Es bezieht ein kostenloses SSL-Zertifikat über Let's Encrypt und aktualisiert die Nginx-Einstellungen, um HTTPS-Verkehr zu erzwingen.

## Abhängigkeitsmanagement (Dependencies)

Die für das Funktionieren des Systems erforderlichen Pakete sind in der Datei `pubspec.yaml` definiert. Die Stärke von Zeytin liegt in der Verwendung der richtigen Pakete für den richtigen Zweck:

- **shelf & shelf_router:** Wird verwendet, damit der Server HTTP-Anfragen abhören und weiterleiten kann. Es ist das Skelett des Webservers.
- **shelf_web_socket:** Verwaltet Socket-Verbindungen für Echtzeit-Datenfluss und den "Watch"-Mechanismus.
- **encrypt:** Stellt die AES-Verschlüsselungsalgorithmen bereit, die von der Klasse `ZeytinTokener` verwendet werden.
- **dart_jsonwebtoken:** Erstellt JWT-Token, um eine sichere Kommunikation mit LiveKit herzustellen.
- **dio:** Ermöglicht es dem Server, HTTP-Anfragen an andere Dienste innerhalb seiner selbst oder in der Außenwelt zu stellen.

Sobald die Installation abgeschlossen ist, sind Sie bereit, das Tool `server/runner.dart` zur Verwaltung des Servers zu verwenden.

# 3. Speicher-Engine

Das grundlegendste Merkmal, das Zeytin von anderen Serverlösungen unterscheidet, ist, dass es über eine eigene Datenbank-Engine verfügt. Diese Engine verwaltet Daten auf dem Dateisystem des Betriebssystems unter Verwendung eines speziellen Binärformats und hochleistungsfähiger Isolationstechniken.

Diese Struktur befindet sich in der Datei `lib/logic/engine.dart` des Systems und basiert auf vier Hauptmechanismen: **Binary Encoder**, **Persistenter Index**, **Isolate-Architektur** und **Compaction**.

## 3.1. Binäres Datenformat

Zeytin verwendet keine textbasierten Formate wie JSON oder XML, wenn Daten auf die Festplatte geschrieben werden. Stattdessen verwendet es, um Speicherplatz zu sparen und die Lese-/Schreibgeschwindigkeit zu erhöhen, ein spezielles Protokoll, das von der Klasse `BinaryEncoder` verwaltet wird.

Daten werden unter Verwendung von `ByteData` und `Uint8List` verarbeitet und in Little-Endian-Reihenfolge gepackt. Jeder Datenblock beginnt mit `0xDB`, dem Magic Byte, um die Datenintegrität zu gewährleisten. Dieses magische Byte hilft der Engine, Datenbeschädigungen zu erkennen.

Die Struktur eines Datenblocks auf der Festplatte ist wie folgt:

| MAGIC (1 Byte) | BOX_ID_LEN (4 Byte) | BOX_ID (N Byte) | TAG_LEN (4 Byte) | TAG (N Byte) | DATA_LEN (4 Byte) | DATA (N Byte) |
| -------------- | ------------------- | --------------- | ---------------- | ------------ | ----------------- | ------------- |
| 0xDB           | 0x00000008          | "settings"      | 0x00000005       | "theme"      | 0x0000000E        | {Binary Map}  |

Dank dieser Struktur kann die Engine, wenn sie zu einer zufälligen Stelle auf der Festplatte geht, fehlerfrei verstehen, wo die Daten beginnen, zu welcher Box und welchem Tag sie gehören und wo die Daten enden.

Unterstützte Datentypen und ihre Identifikationsnummern im System sind:

- `NULL` (0)
- `BOOL` (1)
- `INT` (2) - 64-Bit-Ganzzahl
- `DOUBLE` (3) - 64-Bit-Gleitkommazahl
- `STRING` (4) - UTF8-kodierter Text
- `LIST` (5) - Dynamische Listen
- `MAP` (6) - Schlüssel-Wert-Karten (Maps)

## 3.2. Persistente Indizierung

Das größte Problem von Datenbank-Engines ist, dass die Suchzeit mit wachsender Datenmenge zunimmt. Zeytin löst dieses Problem mit der Klasse `PersistentIndex`.

Das System unterhält eine Indexdatei (`.idx`) gleichzeitig mit der Datendatei (`.dat`). Diese Indexdatei speichert nicht die Daten selbst, sondern die **Adresse** (Offset) und **Größe** (Länge) der Daten auf der Festplatte.

Wenn der Server startet oder ein Truck geladen wird, wird diese Indexdatei vollständig in den Speicher, d. h. RAM, geladen. Wenn Sie also auf Daten zugreifen möchten, scannt das System nicht die Festplatte; es ruft die Koordinaten der Daten direkt aus der Karte im Speicher ab und liest nur diesen Punkt von der Festplatte. Dies stellt sicher, dass die Zugriffszeit im Millisekundenbereich bleibt, selbst wenn die Datengröße Gigabyte beträgt.

Eine beispielhafte Indexkarte sieht im Speicher so aus:

```text
Box: "users"
  └── Tag: "user_123" -> [Offset: 1024, Length: 256]
  └── Tag: "user_456" -> [Offset: 1280, Length: 512]
```

## 3.3. Isolate- und Proxy-Architektur

Von Natur aus hat die Sprache Dart eine Single-Threaded-Struktur. Schwere Festplattenoperationen (I/O) können den Hauptthread blockieren und dazu führen, dass der Server nicht auf andere eingehende Anfragen reagiert. Zeytin verwendet eine Struktur ähnlich dem **Actor Model**, um diesen Engpass zu überwinden.

Jede Benutzerdatenbank, oder Truck, läuft innerhalb eines spezifischen **Isolate** unabhängig vom Hauptserver. Isolates teilen sich keinen Speicher; sie kommunizieren durch Nachrichtenübermittlung miteinander.

1.  **TruckProxy:** Läuft auf der Seite des Hauptservers. Empfängt Anfragen und wandelt sie in eine Nachrichtenwarteschlange um.
2.  **SendPort / ReceivePort:** Die Kommunikationsbrücke zwischen dem Hauptserver und der isolierten Engine.
3.  **TruckIsolate:** Die im Hintergrund laufende Engine mit vollständig getrenntem Speicher und Verarbeitungswarteschlange.

Dank dieser Architektur verlangsamt ein sehr schwerer Massenschreibvorgang, der von einem Benutzer in der Datenbank durchgeführt wird, niemals die Operationen anderer Benutzer oder sofortige Videoanrufe auf dem Server.

## 3.4. Append-Only-Schreiben und Komprimierung (Compaction)

Die Zeytin-Engine arbeitet mit der **Append-Only**-Logik (nur Anfügen), um Datensicherheit zu gewährleisten. Wenn Sie Daten aktualisieren oder löschen, werden die alten Daten nicht sofort von der Festplatte gelöscht. Stattdessen wird der neue Zustand der Daten oder ein Zeichen, dass sie gelöscht wurden, ganz am Ende der Datei hinzugefügt und der Index aktualisiert.

Diese Methode minimiert das Risiko von Datenverlust, führt jedoch dazu, dass die Datendatei im Laufe der Zeit anschwillt und sich "tote" Daten darin ansammeln.

Um dies zu verhindern, gibt es einen automatischen **Compaction**-Mechanismus innerhalb der Klasse `Truck`:

1.  Das System wird nach jeweils 500 Schreibvorgängen ausgelöst.
2.  Die Engine erstellt eine temporäre Datei (`_temp.dat`).
3.  Sie überträgt nur die Daten, die **aktiv und gültig** sind, d. h. deren endgültiger Zustand im Index aufgezeichnet ist, in diese neue Datei.
4.  Alte und unnötige Daten bleiben zurück.
5.  Wenn der Vorgang abgeschlossen ist, wird die alte Datei gelöscht und die neue Datei als Hauptdatendatei benannt.

Da dieser Prozess im Hintergrund und isoliert abläuft, reinigt und optimiert sich das System ohne Unterbrechung selbst.

# 4. Sicherheit und Authentifizierung

Zeytin basiert auf zwei Hauptmechanismen, die die Sicherheit von der äußersten Schicht der Anwendung bis zur tiefsten Form der Datenspeicherung adressieren: **Gatekeeper** und **Tokener**.

In diesem Abschnitt werden wir die Gatekeeper-Struktur untersuchen, die Ihren Server vor böswilligen Angriffen schützt, und den Tokener-Mechanismus, der sicherstellt, dass Ihre Daten verschlüsselt über das Netzwerk transportiert werden.

## 4.1. Gatekeeper: Die erste Verteidigungslinie

Gatekeeper ist die erste Komponente, die jede Anfrage begrüßt, die an Ihren Server kommt. Er arbeitet wie ein Türsteher in einem Nachtclub; er entscheidet, wer eintreten darf, wer nicht und wie häufig Anfragen gestellt werden dürfen.

Diese Struktur befindet sich in der Datei `lib/logic/gatekeeper.dart` und bietet aktiven Schutz vor folgenden Bedrohungen:

### DoS- und DDoS-Schutz (Sleep Mode)

Zeytin verfolgt die Gesamtzahl der Anfragen, die an den Server kommen, sofort mithilfe eines globalen Zählers. Wenn der `globalDosThreshold` (Standard: 50.000 Anfragen) überschritten wird, versetzt sich das System automatisch in den **Ruhemodus (Sleep Mode)**.

- **Reaktion:** Der Server gibt einen Fehler 503 Service Unavailable zurück.
- **Nachricht:** "Be quiet! I'm trying to sleep here." (Sei ruhig! Ich versuche hier zu schlafen.)
- **Dauer:** Das System lehnt alle neuen Anfragen für eine bestimmte Dauer (Standard: 5 Minuten) ab und lässt den Prozessor abkühlen.

### Intelligente Ratenbegrenzung (Rate Limiting)

Für jede IP-Adresse wird ein separates Aktivitätsprotokoll geführt. Gatekeeper wendet basierend auf der IP zwei verschiedene Ratenbegrenzungen an:

1.  **Allgemeines Anfragelimit:** Wenn eine IP-Adresse innerhalb von 5 Sekunden mehr Anfragen sendet als der Wert `generalIpRateLimit5Sec` (Standard: 100), wird sie vorübergehend blockiert und erhält einen Fehler 429 Too Many Requests.
2.  **Token-Erstellungslimit:** Der Endpunkt für die Anmeldung und den Token-Erwerb (`/token/create`) ist strenger gegen Brute-Force-Angriffe geschützt. An diesen Endpunkt kann nur 1 Anfrage pro Sekunde gesendet werden.

### IP-Verwaltung (Blacklist & Whitelist)

Sie können über die Datei `config.dart` eine statische IP-Verwaltung durchführen:

- **Blacklist:** Hier hinzugefügte IP-Adressen können unter keinen Umständen auf den Server zugreifen.
- **Whitelist:** Hier hinzugefügte IP-Adressen (z. B. lokales Netzwerk oder Admin-IP) können Operationen durchführen, ohne in Ratenbegrenzungen hängen zu bleiben.

---

## 4.2. Token-Management und Sitzungen

Anstatt sich wie eine zustandslose (stateless) REST-API zu verhalten, verwendet Zeytin Sitzungs-Token, die zeitlich begrenzt sind und im Speicher gehalten werden.

### Token-Lebenszyklus

Wenn ein Benutzer eine Anfrage an die Adresse `/token/create` mit seiner E-Mail und seinem Passwort sendet, verifiziert das System diese Informationen und erstellt eine temporäre UUID (Eindeutige Identität) im Speicher.

- **Lebensdauer:** Token sind ab dem Moment ihrer Erstellung nur **2 Minuten (120 Sekunden)** gültig.
- **Sicherheit:** Diese kurze Lebensdauer stellt sicher, dass ein Angreifer im Falle eines Token-Diebstahls nur sehr wenig Zeit hat, um Operationen durchzuführen.
- **Aktualisierung:** Die Client-Seite muss alle 2 Minuten oder unmittelbar vor der Durchführung einer Operation ein neues Token anfordern.

### Mehrfachkonto-Beschränkung

Gatekeeper begrenzt die Anzahl der Trucks (Konten), die von derselben IP-Adresse aus geöffnet werden können. Standardmäßig kann eine IP-Adresse höchstens 20 verschiedene Konten erstellen. Wird dieses Limit überschritten, wird diese IP-Adresse automatisch gesperrt.

---

## 4.3. Tokener: Ende-zu-Ende-Verschlüsselung

Kritische Datenoperationen auf Zeytin (CRUD-Operationen und WebSocket-Streams) transportieren Daten nicht als Klartext (JSON). Stattdessen transportieren sie sie in verschlüsselten Paketen unter Verwendung des **AES-CBC**-Algorithmus. Die Klasse, die diesen Prozess verwaltet, ist `ZeytinTokener`.

### Verschlüsselungslogik

Der Verschlüsselungsschlüssel jedes Benutzers wird aus seinem eigenen Login-Passwort abgeleitet. Dies bedeutet, dass selbst der Datenbankadministrator den Inhalt der Daten nicht entschlüsseln kann, indem er den Netzwerkverkehr abhört, ohne das Benutzerpasswort zu kennen.

**Datenpaketstruktur:**
Verschlüsselte Daten bestehen aus zwei Teilen: Initialisierungsvektor (IV) und Geheimtext (Ciphertext), mit einem Doppelpunkt (`:`) dazwischen.

Format: `IV_BASE64:CIPHERTEXT_BASE64`

### Beispielanfrage und -antwort

Nehmen wir an, Sie senden eine Anfrage an den Endpunkt `/data/get`, um Daten zu lesen.

**Client-Anfrage (Client Request):**
Der Client sendet die Informationen `box` und `tag` nicht offen, sondern verschlüsselt.

```json
{
  "token": "a1b2c3d4-...",
  "data": "r5T8...IV_BASE64...:e9K1...CIPHERTEXT..."
  // Der Parameter "data" ist ein verschlüsseltes JSON-Objekt: {"box": "settings", "tag": "theme"}
}
```

**Server-Antwort (Server Response):**
Der Server findet die Daten, liest sie und gibt sie wieder verschlüsselt zurück.

```json
{
  "isSuccess": true,
  "message": "Oki doki!",
  "data": "m7Z2...IV_BASE64...:p4L9...CIPHERTEXT..."
  // Wenn entschlüsselt: {"mode": "dark", "fontSize": 14}
}
```

### Client-seitige Integration

Wenn Sie eine Client-Anwendung entwickeln, die mit Zeytin kommunizieren soll, müssen Sie die Logik in der Klasse `ZeytinTokener` an Ihre eigene Sprache anpassen.

1.  **Schlüsselableitung:** Hashen Sie das Passwort des Benutzers mit SHA-256. Das resultierende Byte-Array ist Ihr AES-Schlüssel.
2.  **Verschlüsselung:** Verschlüsseln Sie die JSON-Daten, die Sie senden werden, im AES-CBC-Modus unter Verwendung eines zufällig generierten 16-Byte-IV. Erstellen Sie als Ergebnis den String `IV:VerschlüsselteDaten`.
3.  **Entschlüsselung:** Teilen Sie die vom Server kommende Antwort am Zeichen `:`. Der erste Teil ist der IV, der zweite Teil sind die verschlüsselten Daten. Entschlüsseln Sie die Daten mit demselben Schlüssel.

Dank dieser Struktur ruhen die Daten als Binärdaten in der Datenbank und reisen verschlüsselt über das Netzwerk. Nur der Client mit einer gültigen Sitzung und Kenntnis des Passworts kann die Daten sinnvoll nutzen.

# 5. API-Referenz

Um die Datensicherheit auf höchstem Niveau zu halten, kommuniziert Zeytin an den meisten seiner Endpunkte mit verschlüsselten Datenpaketen anstelle von Standard-JSON. Daher ist das Verständnis des Konzepts der "Verschlüsselten Daten" entscheidend, bevor Sie die API verwenden.

Sofern nicht anders angegeben, muss bei allen Anfragen unter **CRUD**, **Call** und **Watch** der Parameter `data` ein JSON-String sein, der mit dem aus dem Benutzerpasswort abgeleiteten AES-Schlüssel verschlüsselt wurde.

---

## 5.1. Konto- und Sitzungsverwaltung

Diese Endpunkte sind das Tor zur Datenbank-Engine. Daten werden hier im offenen JSON-Format ohne Verschlüsselung gesendet.

### Neues Konto (Truck) erstellen

Erstellt einen neuen Benutzerbereich (Truck) im System.

- **Endpunkt:** `POST /truck/create`
- **Body:**
  ```json
  {
    "email": "beispiel@mail.com",
    "password": "starkes_passwort"
  }
  ```
- **Antwort:** Gibt bei Erfolg die erstellte Truck-ID zurück.

### Konto-ID-Abfrage

Verifiziert E-Mail und Passwort und ruft die Truck-ID des Benutzers ab.

- **Endpunkt:** `POST /truck/id`
- **Body:** E-Mail und Passwort (wie oben).

### Token-Erstellung (Einloggen)

Generiert den temporären Sitzungsschlüssel (Token), der zur Durchführung von Operationen erforderlich ist. Dieses Token ist 2 Minuten (120 Sekunden) gültig.

- **Endpunkt:** `POST /token/create`
- **Body:**
  ```json
  {
    "email": "beispiel@mail.com",
    "password": "starkes_passwort"
  }
  ```
- **Antwort:** `{"token": "token-im-uuid-format"}`

### Token-Löschung (Ausloggen)

Macht ein aktives Token ungültig, bevor es abläuft.

- **Endpunkt:** `DELETE /token/delete`
- **Body:** E-Mail und Passwort.

---

## 5.2. Admin-Operationen (Nur Localhost)

Diese Endpunkte sind nur auf Localhost-Zugriff beschränkt und erfordern einen Admin-Geheimschlüssel. Sie sind für Serveradministratoren konzipiert, um Benutzerkonten direkt vom Serverrechner aus zu verwalten.

### Neues Konto erstellen (Admin)

Erstellt ein neues Benutzerkonto. Nur von Localhost (127.0.0.1, ::1) aus zugänglich.

- **Endpunkt:** `POST /admin/truck/create`
- **Zugriff:** Nur Localhost
- **Body:**
  ```json
  {
    "adminSecret": "ihr-admin-secret-aus-config",
    "email": "neuerbenutzer@beispiel.com",
    "password": "sicheres_passwort"
  }
  ```
- **Antwort:** Gibt die erstellte Truck-ID und Kontodetails zurück.

### Kontopasswort ändern (Admin)

Ändert das Passwort für ein bestehendes Konto. Nur von Localhost aus zugänglich.

- **Endpunkt:** `POST /admin/truck/changePassword`
- **Zugriff:** Nur Localhost
- **Body:**
  ```json
  {
    "adminSecret": "ihr-admin-secret-aus-config",
    "email": "benutzer@beispiel.com",
    "newPassword": "neues_sicheres_passwort"
  }
  ```
- **Antwort:** Gibt Erfolgsbestätigung mit aktualisierten Kontodetails zurück.

> **Sicherheitshinweis:** Das `adminSecret` ist in `lib/config.dart` definiert und sollte vertraulich behandelt werden. Auf diese Endpunkte kann nicht von externen Netzwerken aus zugegriffen werden.

---

## 5.3. Datenoperationen (CRUD)

Alle Anfragen in diesem Abschnitt nehmen zwei Parameter entgegen:

1.  `token`: Der gültige Sitzungsschlüssel, der von `/token/create` erhalten wurde.
2.  `data`: Der **verschlüsselte** String, der die Parameter der angeforderten Operation enthält.

> **Hinweis:** In den folgenden Beispielen wird der Inhalt von `data` in seinem (offenen) Zustand vor der Verschlüsselung gezeigt. In einer echten Anfrage muss dieses JSON mit `ZeytinTokener` verschlüsselt und gesendet werden.

### Daten hinzufügen / aktualisieren

Schreibt Daten in die angegebene Box (Box) und das Tag (Etikett/Tag). Wenn das Tag existiert, wird es aktualisiert; wenn nicht, wird es erstellt.

- **Endpunkt:** `POST /data/add`
- **Verschlüsselter Dateninhalt:**
  ```json
  {
    "box": "einstellungen",
    "tag": "thema",
    "value": { "modus": "dunkel", "farbe": "blau" }
  }
  ```

### Massendaten hinzufügen (Batch)

Schreibt mehrere Datenstücke auf einmal in eine einzelne Box. Sollte aus Leistungsgründen bevorzugt werden.

- **Endpunkt:** `POST /data/addBatch`
- **Verschlüsselter Dateninhalt:**
  ```json
  {
    "box": "produkte",
    "entries": {
      "produkt_1": { "name": "Laptop", "preis": 5000 },
      "produkt_2": { "name": "Maus", "preis": 100 }
    }
  }
  ```

### Daten lesen (Einzeln)

Ruft Daten in einem bestimmten Tag ab.

- **Endpunkt:** `POST /data/get`
- **Verschlüsselter Dateninhalt:** `{ "box": "einstellungen", "tag": "thema" }`
- **Antwort:** Gibt verschlüsselte Daten zurück. Muss auf der Client-Seite entschlüsselt werden.

### Box lesen (Alle)

Ruft alle Daten in einer Box ab. Sollte vorsichtig verwendet werden; der Vorgang kann in großen Boxen lange dauern.

- **Endpunkt:** `POST /data/getBox`
- **Verschlüsselter Dateninhalt:** `{ "box": "produkte" }`

### Daten löschen

Löscht ein bestimmtes Tag und seine Daten.

- **Endpunkt:** `POST /data/delete`
- **Verschlüsselter Dateninhalt:** `{ "box": "einstellungen", "tag": "thema" }`

### Box löschen

Löscht eine Box und alle darin enthaltenen Daten vollständig.

- **Endpunkt:** `POST /data/deleteBox`
- **Verschlüsselter Dateninhalt:** `{ "box": "verlaufs_logs" }`

### Existenzprüfungen

Leichtgewichtige Endpunkte, die prüfen, ob Daten existieren. Sie geben nur `true/false`-Informationen verschlüsselt zurück, nicht die Daten selbst.

- **Tag existiert?:** `POST /data/existsTag` -> `{ "box": "...", "tag": "..." }`
- **Box existiert?:** `POST /data/existsBox` -> `{ "box": "..." }`
- **Inhaltsprüfung:** `POST /data/contains` -> `{ "box": "...", "tag": "..." }` (Verifiziert die physische Existenz von Daten im Speicher oder auf der Festplatte).

### Suchen und Filtern

- **Präfix-Suche (Search):** Sucht, ob der Wert in einem Feld mit einem bestimmten Wort (Präfix) beginnt.
  - **Endpunkt:** `POST /data/search`
  - **Verschlüsselte Daten:** `{ "box": "benutzer", "field": "name", "prefix": "Ahmet" }`

- **Genaue Übereinstimmung (Filter):** Ruft Datensätze ab, bei denen der Wert in einem Feld genau übereinstimmt.
  - **Endpunkt:** `POST /data/filter`
  - **Verschlüsselte Daten:** `{ "box": "benutzer", "field": "alter", "value": 25 }`

---

## 5.3. Dateispeicherung (Storage)

Datei-Upload-Vorgänge werden im Standardformat `multipart/form-data` durchgeführt. Verschlüsselung wird nicht verwendet, aber ein Token ist obligatorisch.

### Datei hochladen

- **Endpunkt:** `POST /storage/upload`
- **Methode:** Multipart Form Data
- **Felder:**
  - `token`: Gültiger Sitzungsschlüssel (String).
  - `file`: Hochzuladende Datei (Binary).
- **Einschränkungen:** Ausführbare Dateien wie `.exe`, `.php`, `.sh`, `.html` usw. werden aus Sicherheitsgründen abgelehnt.

### Datei herunterladen / anzeigen

Hochgeladene Dateien werden öffentlich bereitgestellt.

- **Endpunkt:** `GET /<truckId>/<dateiname>`
- **Beispiel:** `GET /a1b2-c3d4.../profilbild.jpg`

---

## 5.4. Live-Überwachung (Watch - WebSocket)

Ermöglicht es Clients, Änderungen in der Datenbank (Hinzufügen, Löschen, Aktualisieren) sofort zu hören.

- **Endpunkt:** `ws://server-adresse/data/watch/<token>/<boxId>`
- **Parameter:** Gültiges `token` und die zu überwachende `boxId` müssen in der URL angegeben werden.
- **Ereignisstruktur:** Vom Server kommende Nachrichten enthalten JSON im folgenden Format:
  ```json
  {
    "op": "PUT", // Operationstyp: PUT, UPDATE, DELETE, BATCH
    "tag": "geändertes_daten_tag",
    "data": "VERSCHLÜSSELTE_DATEN", // Verschlüsselter neuer Wert
    "entries": null // Nur bei Batch-Operationen gefüllt
  }
  ```

---

## 5.5. Anruf und Übertragung (Call - LiveKit)

Zeytin arbeitet integriert mit dem LiveKit-Server, um die notwendige "Raum"-Verwaltung (Room) für Sprach- und Videoanrufe bereitzustellen.

### Raum beitreten (Token erhalten)

Generiert ein LiveKit-Zugangstoken, um einen Anruf zu starten oder einem bestehenden Raum beizutreten.

- **Endpunkt:** `POST /call/join`
- **Verschlüsselter Dateninhalt:**
  ```json
  {
    "roomName": "besprechungsraum_1",
    "uid": "benutzer_123"
  }
  ```
- **Antwort:** Gibt die LiveKit-Serveradresse und das JWT-Token verschlüsselt zurück.

---

## 5.6. E-Mail-Dienst (Mail)

Zeytin verfügt über einen integrierten SMTP-Client, mit dem Sie E-Mails über Ihr System an Ihre Benutzer oder externe Adressen senden können. Für diesen Vorgang müssen gültige SMTP-Einstellungen (Host, Port, Benutzername, Passwort) in der Datei `config.dart` auf der Serverseite konfiguriert sein.

Aus Gründen der Datensicherheit werden der Inhalt der zu sendenden E-Mail und die Empfängerinformationen nicht als Klartext über das Netzwerk transportiert. Der Parameter `data` muss mit AES verschlüsselt sein.

### Benutzerdefinierte E-Mail senden

Sendet eine E-Mail an die angegebene Adresse mit dem von Ihnen festgelegten Betreff und HTML-Inhalt.

- **Endpunkt:** `POST /mail/send`
- **Verschlüsselter Dateninhalt:**
  ```json
  {
    "to": "benutzer@beispiel.com",
    "subject": "Willkommen in unserem System!",
    "html": "<h1>Hallo!</h1><p>Ihr Konto wurde erfolgreich erstellt.</p>"
  }
  ```
- **Antwort:** Wenn der Vorgang erfolgreich ist, wird `{"isSuccess": true, "message": "Email deployed successfully!"}` zurückgegeben.

### Raumstatusprüfung

Prüft, ob in einem Raum ein aktiver Anruf stattfindet.

- **Endpunkt:** `POST /call/check`
- **Verschlüsselter Dateninhalt:** `{ "roomName": "besprechungsraum_1" }`
- **Antwort:** Gibt `isActive` (boolean) Wert verschlüsselt zurück.

### Live-Raum-Verfolgung (Stream)

Verfolgt den Aktivitätsstatus eines Raums kontinuierlich über WebSocket.

- **Endpunkt:** `ws://server-adresse/call/stream/<token>?data=VERSCHLÜSSELTE_DATEN`
- **Parameter:**
  - `token` im URL-Pfad.
  - `data` als Query-Parameter: `{ "roomName": "..." }` (Verschlüsselt).
- **Verhalten:** Wenn sich der Raumstatus ändert (wenn jemand eintritt oder die letzte Person geht), sendet der Server eine sofortige Benachrichtigung.

# 6. Serververwaltung

Zeytin ist nicht nur Software; es ist ein lebendiges System. Wir haben ein interaktives Verwaltungspanel namens **Runner** entwickelt, damit Sie sich nicht mit komplexen Linux-Befehlen (kill, nohup, tail usw.) befassen müssen, um dieses System zu verwalten.

Die Datei `server/runner.dart` ist das Cockpit Ihres Servers. Alle operativen Aufgaben wie Starten, Stoppen, Aktualisieren und Überwachen von Logs werden von hier aus erledigt.

## Starten des Runners

Wenn Sie sich per SSH mit Ihrem Server verbinden, geben Sie einfach den folgenden Befehl ein, um die Verwaltungsoberfläche zu öffnen:

```bash
dart server/runner.dart
```

Sie werden mit einem farbigen und nummerierten Menü konfrontiert. Wir haben unten detailliert beschrieben, was die Optionen in diesem Menü bewirken und was sie im Hintergrund tun.

---

## 6.1. Ausführungsmodi

Es werden zwei verschiedene Optionen angeboten, um das System zu starten. Es ist wichtig zu wissen, welche in welcher Situation zu verwenden ist.

### 1. Start Test Mode (Testmodus starten)

Diese Option startet den Server sofort im aktuellen Terminalfenster ohne Kompilierung.

- **Anwendungsfall:** Verwenden Sie dies, wenn Sie Änderungen am Code vorgenommen haben und schnell testen möchten.
- **Verhalten:** Wenn Sie das Terminal schließen oder `CTRL+C` drücken, wird auch der Server geschlossen. Er gibt Fehler und Ausgaben direkt auf dem Bildschirm aus.
- **LiveKit-Check:** Prüft vor dem Start, ob der Docker-Container läuft; falls geschlossen, öffnet er ihn automatisch.

### 2. Start Live Mode (Live-Modus starten)

Diese Option bereitet den Server für eine echte Produktionsumgebung vor.

- **Kompilierung:** Konvertiert den Dart-Code in Maschinensprache (im `.exe`-Format) und erstellt eine optimierte Datei. Dadurch läuft der Server viel schneller und verbraucht weniger Speicher.
- **Hintergrundbetrieb:** Verschiebt den Server mit dem Befehl `nohup` in den Hintergrund. Selbst wenn Sie Ihre SSH-Verbindung trennen, läuft der Server weiter.
- **Logs:** Schreibt alle Ausgaben in die Datei `zeytin.log`.
- **PID-Verfolgung:** Speichert die ID-Nummer des laufenden Prozesses in der Datei `server.pid`. Auf diese Weise können Sie den Server später einfach stoppen.

---

## 6.2. Überwachung und Kontrolle

Sie können diese Optionen verwenden, um den Status des Servers zu verfolgen, während er läuft, oder um einzugreifen.

### 3. Watch Logs (Logs ansehen)

Dient dazu, sofort zu sehen, was der im Hintergrund (Live Mode) laufende Server tut. Führt den Befehl `tail -f zeytin.log` aus. Sie können `CTRL+C` drücken, um den fließenden Text auf dem Bildschirm zu stoppen; dieser Vorgang schließt den Server nicht, er verlässt nur den Überwachungsbildschirm.

### 4. Stop Server (Server stoppen)

Schließt den laufenden Zeytin-Server sicher. Runner schaut zuerst in die Datei `server.pid` und beendet den entsprechenden Prozess. Wenn die Datei nicht existiert oder gelöscht wurde, bereinigt er zwangsweise alle Zeytin-Prozesse im System.

---

## 6.3. Wartungs- und Infrastrukturoperationen

Dies sind notwendige Werkzeuge, um die Aktualität und Gesundheit des Systems zu erhalten.

### 6. UPDATE SYSTEM (System aktualisieren)

Verwenden Sie diese Option, wenn ein neues Update im GitHub-Repository veröffentlicht wird. Dieser Prozess führt nacheinander Folgendes aus:

1.  Erstellt ein Backup Ihrer bestehenden `config.dart`-Datei. (Ihre Einstellungen gehen nicht verloren)
2.  Lädt die neuesten Codes mit dem Befehl `git pull` auf den Server herunter.
3.  Stellt die gesicherte Konfigurationsdatei wieder her.
4.  Lädt die neu hinzugefügten Bibliotheken mit `dart pub get` herunter.
5.  Sie müssen den Server neu starten, wenn der Vorgang abgeschlossen ist.

### 7. Clear Database & Storage (Datenbank & Speicher bereinigen)

Diese Option ist **gefährlich**. Sie stoppt den Server und löscht dauerhaft alle Benutzerdaten, Dateien und Indizes im Ordner `zeytin/`. Verwenden Sie dies, wenn Sie einen sauberen Neustart von Grund auf machen möchten.

### 5. UNINSTALL SYSTEM (System deinstallieren)

Die gefährlichste Option. Sie stoppt den Server und löscht den gesamten Projektordner von der Festplatte. Es gibt kein Zurück.

---

## 6.4. Nginx-Verwaltung

Wenn Sie die SSL- und Domain-Einstellungen während der Installationsphase nicht vorgenommen haben oder sie ändern möchten, können Sie dieses Menü verwenden.

### 8. Nginx & SSL Setup

Löst die Datei `install.sh` erneut aus. Wird verwendet, um eine neue Domain zu definieren oder ein SSL-Zertifikat zu erhalten.

### 9. Remove Nginx Config (Nginx-Konfiguration entfernen)

Löscht die für Zeytin erstellten Nginx-Einstellungsdateien und Verknüpfungen und startet dann den Nginx-Dienst neu. Ihr Server antwortet nicht mehr auf die Außenwelt (Ports 80/443), er arbeitet nur noch vom lokalen Port (12852).


---

## 6.5. Datenbank-Manager

Zusätzlich zum Runner bietet Zeytin ein dediziertes Datenbankverwaltungstool für erweiterte Operationen. Die Datei `server/db_manager.dart` bietet eine interaktive Terminalschnittstelle für die direkte Datenbankmanipulation.

### Starten des Datenbank-Managers

```bash
dart server/db_manager.dart
```

Dies öffnet eine menügesteuerte Schnittstelle mit folgenden Funktionen:

**Kontoverwaltung:**
- Alle Benutzerkonten mit Details auflisten (E-Mail, Erstellungsdatum, Truck-ID)
- Neue Konten erstellen
- Zwischen Konten auswählen und wechseln
- Konten und alle zugehörigen Daten löschen

**Box-Verwaltung:**
- Alle Boxen innerhalb eines ausgewählten Kontos auflisten
- Eine Box zum Arbeiten auswählen
- Boxen und deren Inhalte löschen
- Elementanzahl pro Box anzeigen

**Datenoperationen:**
- Alle Datenelemente in einer Box auflisten
- Spezifische Daten nach Tag abrufen
- Innerhalb einer Box suchen (präfixbasiert)
- Über alle Boxen hinweg suchen
- Neue Daten hinzufügen (JSON-Format)
- Daten nach Tag löschen

**Systemstatistiken:**
- Gesamtzahl der Konten
- Gesamtzahl der Boxen
- Gesamtdatenelemente im gesamten System
- Datenbankpfadinformationen

> **Anwendungsfall:** Der Datenbank-Manager ist ideal für Debugging, Dateninspektion, manuelle Dateneingabe und Systemwartungsaufgaben. Er bietet direkten Zugriff auf die Speicher-Engine, ohne die REST-API zu durchlaufen.

---

## 6.6. Konfigurationsreferenz

Die Datei `lib/config.dart` enthält kritische Systemparameter. Hier sind die wichtigsten Einstellungen, die Sie kennen sollten:

**Sicherheitseinstellungen:**
- `adminSecret`: Geheimer Schlüssel für Admin-Operationen. Ändern Sie dies sofort nach der Installation.
- `blacklistedIPs`: Liste der IP-Adressen, die dauerhaft vom Zugriff auf den Server blockiert sind.
- `whitelistedIPs`: Liste der IP-Adressen, die von der Ratenbegrenzung ausgenommen sind.

**Systemgrenzen:**
- `maxTruckCount`: Maximale Anzahl von Benutzerkonten, die im System zulässig sind (Standard: 10.000).
- `maxTruckPerIp`: Maximale Konten, die von einer einzelnen IP-Adresse erstellt werden können (Standard: 20).
- `truckCreationCooldownMs`: Abkühlzeit zwischen Kontoerstellungen von derselben IP (Standard: 10 Minuten).

**Ratenbegrenzung:**
- `globalDosThreshold`: Gesamtanforderungsschwelle, bevor der Ruhemodus aktiviert wird (Standard: 50.000).
- `generalIpRateLimit5Sec`: Maximale Anfragen pro IP in 5 Sekunden (Standard: 100).

**LiveKit-Einstellungen:**
- `liveKitUrl`: LiveKit-Serveradresse (während der Installation automatisch konfiguriert).
- `liveKitApiKey` & `liveKitApiSecret`: Authentifizierungsdaten für die LiveKit-Integration.

**SMTP-Einstellungen:**
- `smtpHost`, `smtpPort`, `smtpUsername`, `smtpPassword`: E-Mail-Serverkonfiguration für den Mail-Dienst.

> **Wichtig:** Nach dem Ändern von `config.dart` müssen Sie den Server neu starten, damit die Änderungen wirksam werden.

---

# 7. Testen und Qualitätssicherung

Zeytin enthält eine umfassende Testsuite, um die Systemzuverlässigkeit zu gewährleisten und Regressionen frühzeitig zu erkennen. Die Testinfrastruktur deckt alle kritischen Komponenten des Systems ab.

## Tests ausführen

Um die vollständige Testsuite auszuführen:

```bash
dart test test/all_tests.dart
```

Dies führt über 196 Testfälle aus, die Folgendes abdecken:

- **Kontoverwaltung:** Benutzererstellung, Authentifizierung und Kontooperationen
- **Admin-Operationen:** Admin-Endpunktsicherheit und -funktionalität
- **Speicher-Engine:** Binärkodierung, Indizierung und Datenpersistenz
- **Gatekeeper:** Ratenbegrenzung, IP-Blockierung und DoS-Schutz
- **Token-Verwaltung:** Sitzungshandhabung und Verschlüsselung
- **CRUD-Operationen:** Daten-Lese-/Schreiboperationen und Suchfunktionalität
- **Datenbank-Manager:** Direkte Datenbankmanipulation und Verwaltungstools

## Teststruktur

Einzelne Testdateien befinden sich im Verzeichnis `test/`:

- `account_test.dart` - Kontoerstellungs- und Anmeldetests
- `admin_test.dart` - Admin-Endpunktsicherheitstests
- `engine_test.dart` - Speicher-Engine- und Isolationstests
- `gatekeeper_test.dart` - Sicherheits- und Ratenbegrenzungstests
- `tokener_test.dart` - Verschlüsselungs- und Token-Tests
- `db_manager_simple_test.dart` - Datenbank-Manager-Funktionalitätstests
- `routes_test.dart` - API-Endpunkt-Integrationstests

## Kontinuierliche Integration

Tests sollten vor der Bereitstellung von Updates in der Produktion ausgeführt werden. Die Testsuite ist so konzipiert, dass sie in unter 3 Sekunden abgeschlossen wird, was sie für schnelle Entwicklungszyklen geeignet macht.

```bash
# Spezifische Testdatei ausführen
dart test test/admin_test.dart

# Mit ausführlicher Ausgabe ausführen
dart test test/all_tests.dart -v
```

---

# 8. Fazit

Zeytin stellt einen Paradigmenwechsel in der Backend-Architektur dar, indem es die traditionelle Trennung zwischen Anwendungsserver und Datenbank beseitigt. Dieser einheitliche Ansatz bietet:

- **Vereinfachte Infrastruktur:** Keine externe Datenbank zum Installieren, Konfigurieren oder Warten
- **Verbesserte Leistung:** Direkter Speicherzugriff ohne Netzwerklatenz
- **Integrierte Sicherheit:** Mehrschichtiger Schutz von Gatekeeper bis Ende-zu-Ende-Verschlüsselung
- **Entwicklererfahrung:** Intuitive Verwaltungstools und umfassende Tests

Egal, ob Sie eine Echtzeitanwendung, eine sichere Datenplattform oder einen Multimedia-Dienst erstellen, Zeytin bietet die Grundlage, die Sie benötigen, mit minimaler Komplexität und maximaler Kontrolle.

Für Fragen, Beiträge oder Support besuchen Sie das [GitHub-Repository](https://github.com/JeaFrid/Zeytin).

---

_Mit ❤️ von JeaFriday für die Entwickler-Community erstellt._

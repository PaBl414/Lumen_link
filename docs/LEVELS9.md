# Dziewięć poziomów — aktualne zasady i rozwiązania

Rozszerzenie po M11c. Źródła: `data/levels.json`, `data/maps/*.json`, `core/obstacle_system.gd`, `core/link_system.gd`, `core/simulation.gd`, `app/match_session.gd`. Wcześniejsze opisy M11c są dokumentacją historyczną trzech oryginalnych układów; poniższe reguły zastępują przenoszenie zdrowia i punktów między sektorami.

## Gra i współpraca

Każdy poziom: trzy cele w kolejności 0→1→2, potem oba drony w wyjściu (1168,592), promień64, przez120 ticków. Gracze mają wspólną integralność: Normal6, Relaxed9; nowy poziom i powtórka przywracają pełną właściwą wartość. Wynik i czas są liczone osobno dla poziomu, bez przenoszenia między mapami. Czas rekordu to `sector_tick/60`, obejmuje ewakuację, pomija odliczanie180 ticków. Limit czasu pozostaje Normal180s / Relaxed240s.

Ruch240, przyspieszenie1800, hamowanie2400, dron24×24; zryw720 przez10 ticków, cooldown90. Normalne sterowanie LAN: WASD, Spacja (zryw), E (zaczep), Q (ping). E w odległości36 od zaczepu przełącza aktywny zaczep albo go odłącza, cooldown30. Oba stanowiska są zamienne. Lokalny test F2: P1 WASD/Spacja/E/Q, P2 IJKL/Shift/U/O. Escape w grze pokazuje menu i neutralizuje wejście; symulacja nadal biegnie.

Przewód: długość56–720, kolizja ścian/przesłon z marginesem3; cel w odległości≤25 od przewodu i co najmniej48 po łuku od obu końców. Ramiona mogą się nakładać, drony mogą się nakładać, nie ma minimum kąta. Pola wymagają różnych dronów w NORMAL, radius44, para rozdzielona≥160; pola same nie dostarczają energii. Cel300 ticków; po przerwie30 ticków ubytek1 co2 ticki. Cel dwufazowy zatrzaskuje150 i aktywuje drugą nieruchomą parę; późniejszy zanik zatrzymuje się na150. Na kolejnej mapie zatrzaski są czyszczone.

PULSE i SWEEP zachowują dotychczasowe harmonogramy i obrażenia. Nowe przeszkody nie ranią i nie blokują ruchu:

- **SHUTTER / przesłona optyczna:** zamknięta blokuje każdy przecinający ją odcinek przewodu, również drugie ramię przy zaczepie. Obrys i napis rozróżniają otwarcie, żółtą zapowiedź i zamknięcie z krzyżem. Znacznik blokady wypada na faktycznym kontakcie wiązki.
- **JAM / strefa zakłóceń:** aktywna strefa wyłącza całą parę, jeżeli zahacza o nią collider dowolnego drona. Sama wiązka może ją przecinać. Zryw i odporność na obrażenia nie wyłączają zakłócenia. Fioletowy obrys, żółta zapowiedź i komunikat celu wyjaśniają przerwę. Można wyjść w dowolnym kierunku i natychmiast odzyskać zasilanie, o ile pozostałe warunki są spełnione.

Harmonogram `[OFF,WARN,ACTIVE]` jest zapisany osobno dla obu trudności w tickach hosta. `phase_tick=(sector_tick+floor(offset*period/base_period)+37*variant)%period`. Seed wybiera tylko jeden z trzech wariantów faz, nie tworzy nowych poziomów. Typowe nowe cykle to360/90/60 (8.5s), Relaxed420/120/45 (9.75s); konkretne różnice niżej. Zapowiedzi nowych map trwają90 lub120 ticków. Weryfikacja rzeczywistymi komendami obejmuje komplet54 konfiguracji, a nie tylko statyczne ustawienie końców.

## Katalog i różnice poziomów

Stabilne ID są kluczami danych, wyników i protokołu. Numer jest wyliczany z kolejności katalogu; limit64 w protokole jest limitem formatu, nie długością kampanii. Oryginalne pliki dock/garden/reactor zachowano.

### 1. Dok — `dock`

Nauka: bezpieczny prosty przewód, narożnik z zaczepem, potem jedna para pól i PULSE.

Ściany `[x,y,w,h]`: [344, 296, 24, 184], [400, 272, 32, 24], [432, 180, 392, 132], [368, 344, 64, 136], [432, 328, 392, 152].

Zaczepy (indeksy0…): [384, 320].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [112, 440] | [304, 440] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 2/1 | [384, 192] | [904, 320] | 0 / P0 | Ustawcie końce i zasilcie. |
| 3/1 | [896, 552] | [1120, 552] | odłączony / P0 | Ustawcie końce i zasilcie. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/dock_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

Hazardy: {'id': 0, 'type': 'PULSE', 'a': [896, 552], 'radius': 48, 'phase_offset': 0}.

### 2. Ogród — `garden`

Ruch między dwiema parami, powrót po SWEEP i przełączenie zaczepu przy zachowanym150.

Ściany `[x,y,w,h]`: [600, 224, 112, 160], [936, 208, 96, 152].

Zaczepy (indeksy0…): [544, 448], [880, 384], [1056, 512].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [112, 256] | [400, 256] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 1/2 | [160, 176] | [352, 336] | odłączony / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |
| 2/1 | [544, 224] | [800, 448] | 0 / P0 | Ustawcie końce i zasilcie. |
| 3/1 | [880, 224] | [1104, 384] | 1 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [776, 192] | [944, 624] | 2 / P1 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/garden_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

Hazardy: {'id': 0, 'type': 'SWEEP', 'a': [480, 152], 'b': [480, 296], 'travel': [128, 0], 'phase_offset': 0}, {'id': 1, 'type': 'PULSE', 'a': [1056, 432], 'radius': 48, 'phase_offset': 100}.

### 3. Reaktor — `reactor`

Rozdzielenie geometrią, naprzemienne stanowiska PULSE, finał zaczep/PULSE/SWEEP.

Ściany `[x,y,w,h]`: [272, 192, 112, 192], [744, 136, 144, 120], [784, 448, 48, 96].

Zaczepy (indeksy0…): [208, 448], [672, 320], [1008, 592].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [208, 208] | [448, 448] | 0 / P0 | Ustawcie końce i zasilcie. |
| 2/1 | [672, 160] | [1008, 320] | 1 / P0 | Ustawcie końce i zasilcie. |
| 2/2 | [672, 480] | [1168, 320] | 1 / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |
| 3/1 | [672, 480] | [1056, 584] | 1 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [768, 304] | [1168, 512] | 2 / P1 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/reactor_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

Hazardy: {'id': 0, 'type': 'SWEEP', 'a': [144, 144], 'b': [144, 272], 'travel': [128, 0], 'phase_offset': 0}, {'id': 1, 'type': 'PULSE', 'a': [672, 160], 'radius': 48, 'phase_offset': 0}, {'id': 2, 'type': 'PULSE', 'a': [1008, 320], 'radius': 48, 'phase_offset': 30}, {'id': 3, 'type': 'PULSE', 'a': [672, 480], 'radius': 48, 'phase_offset': 0}, {'id': 4, 'type': 'PULSE', 'a': [1168, 320], 'radius': 48, 'phase_offset': 30}, {'id': 5, 'type': 'PULSE', 'a': [768, 304], 'radius': 48, 'phase_offset': 0}, {'id': 6, 'type': 'SWEEP', 'a': [944, 464], 'b': [944, 624], 'travel': [96, 0], 'phase_offset': 90}.

### 4. Rozdzielnia — `switchyard`

Wybór dwóch użytecznych tras dla tej samej pary końców: zaczep0 daje dłuższe688, zaczep1 krótsze569.6, lecz jego dojście przecina PULSE. Potem niezależny narożnik i odłączenie zaczepu przed obrotem przewodu. Nowe zadanie: porównanie bezpieczniejszego dojścia z krótszą wiązką.

Ściany `[x,y,w,h]`: [272, 224, 128, 96], [816, 144, 96, 80], [512, 336, 112, 48], [944, 352, 128, 24], [496, 136, 64, 112], [1104, 144, 24, 80].

Zaczepy (indeksy0…): [176, 448], [352, 448], [752, 288].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [176, 208] | [624, 448] | 1 / P0 | Ustawcie końce i zasilcie. |
| 2/1 | [752, 144] | [1040, 288] | 2 / P0 | Ustawcie końce i zasilcie. |
| 3/1 | [848, 528] | [1168, 528] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [944, 432] | [1136, 624] | odłączony / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/switchyard_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

Hazardy: {'id': 0, 'type': 'PULSE', 'a': [352, 448], 'radius': 48, 'phase_offset': 0}, {'id': 1, 'type': 'SWEEP', 'a': [688, 432], 'b': [688, 600], 'travel': [96, 0], 'phase_offset': 90}.

### 5. Kanały serwisowe — `service_channels`

Długa środkowa przegroda dzieli przejścia. Jeden gracz idzie górą obok SWEEP, drugi dołem obok PULSE; końce ponownie synchronizują się przy lewym i prawym zaczepie. Nowe zadanie: skoordynowanie dwóch osobnych korytarzy zamiast wspólnego podejścia do urządzenia.

Ściany `[x,y,w,h]`: [224, 352, 832, 48], [352, 584, 112, 40], [784, 440, 64, 40], [944, 584, 64, 40], [432, 128, 80, 48], [704, 224, 96, 64], [1008, 128, 48, 96].

Zaczepy (indeksy0…): [176, 432], [1120, 432].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [112, 240] | [112, 560] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 2/1 | [176, 208] | [624, 528] | 0 / P0 | Ustawcie końce i zasilcie. |
| 3/1 | [1120, 144] | [832, 528] | 1 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [1120, 304] | [688, 576] | 1 / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/service_channels_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

Hazardy: {'id': 0, 'type': 'SWEEP', 'a': [336, 144], 'b': [336, 272], 'travel': [160, 0], 'phase_offset': 0}, {'id': 1, 'type': 'PULSE', 'a': [448, 528], 'radius': 48, 'phase_offset': 100}, {'id': 2, 'type': 'PULSE', 'a': [1120, 224], 'radius': 48, 'phase_offset': 30}.

### 6. Obserwatorium — `observatory`

Bezpieczne wprowadzenie przesłony na prostej wiązce. Następnie dwa zaczepy omijają ściany innymi ramionami, a przesłony mają różne przesunięcia faz. Dla celu1 przy tych samych końcach można użyć zaczepu0 lub1, zależnie od otwartego ramienia. Nowe zadanie: wybór optycznego okna, które nie ogranicza drogi samych dronów.

Ściany `[x,y,w,h]`: [720, 136, 112, 48], [880, 384, 64, 64], [480, 320, 96, 80], [1056, 144, 48, 96], [576, 536, 96, 48].

Zaczepy (indeksy0…): [656, 240], [912, 336], [1056, 600].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [208, 240] | [464, 240] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 2/1 | [656, 144] | [1008, 240] | 0 / P0 | Ustawcie końce i zasilcie. |
| 3/1 | [720, 336] | [1168, 600] | 2 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [608, 248] | [944, 600] | 2 / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/observatory_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

| Typ / ID | Obszar | Normal OFF/WARN/ACTIVE | Relaxed | Offset |
|---|---|---|---|---|
| SHUTTER/0 | [320, 184, 24, 112] | [360, 90, 90] | [420, 120, 60] | 0 |
| SHUTTER/1 | [840, 208, 24, 48] | [420, 90, 90] | [480, 120, 60] | 0 |
| SHUTTER/2 | [704, 184, 32, 24] | [420, 90, 90] | [480, 120, 60] | 300 |
| SHUTTER/3 | [896, 464, 32, 80] | [360, 90, 90] | [420, 120, 60] | 120 |

Hazardy: {'id': 0, 'type': 'PULSE', 'a': [944, 600], 'radius': 48, 'phase_offset': 60}.

### 7. Komora zakłóceń — `interference`

Bezpieczny pierwszy kontakt z JAM: wyjście z obrysu i powrót. Potem przy zaczepie zagłuszane jest drugie stanowisko; ostatnie zadanie przekazuje presję między graczami. Nowe zadanie: usunięcie drona ze strefy zamiast omijania jej samym przewodem.

Ściany `[x,y,w,h]`: [656, 208, 128, 144], [976, 208, 112, 144], [304, 320, 144, 48], [400, 128, 48, 48], [656, 576, 112, 40], [1120, 144, 48, 96].

Zaczepy (indeksy0…): [592, 448], [928, 528].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [208, 240] | [464, 240] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 2/1 | [592, 208] | [976, 448] | 0 / P0 | Ustawcie końce i zasilcie. |
| 3/1 | [928, 320] | [1168, 528] | 1 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [928, 144] | [1040, 528] | 1 / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/interference_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

| Typ / ID | Obszar | Normal OFF/WARN/ACTIVE | Relaxed | Offset |
|---|---|---|---|---|
| JAM/0 | [160, 192, 96, 96] | [330, 90, 90] | [420, 120, 60] | 240 |
| JAM/1 | [920, 400, 112, 96] | [330, 90, 90] | [420, 120, 60] | 0 |
| SHUTTER/2 | [784, 416, 24, 64] | [360, 90, 60] | [420, 120, 45] | 120 |
| JAM/3 | [880, 272, 96, 96] | [330, 90, 90] | [420, 120, 60] | 0 |
| JAM/4 | [992, 480, 96, 96] | [330, 90, 90] | [420, 120, 60] | 240 |

Hazardy: {'id': 0, 'type': 'PULSE', 'a': [832, 592], 'radius': 48, 'phase_offset': 90}.

### 8. Rdzeń pomocniczy — `aux_core`

Wszystkie cele mają dwa etapy. Najpierw obrót wolnej wiązki, potem dwie zmiany zaczepu. Wewnętrzne przejścia skracają dojście, ale przecinają SWEEP/PULSE/JAM; zewnętrzna droga pozwala ominąć ich zasięg. Nowe zadanie: wybór drogi podczas każdej zmiany obwodu przy zachowaniu150.

Ściany `[x,y,w,h]`: [448, 136, 48, 112], [696, 144, 144, 192], [976, 224, 80, 64], [512, 432, 112, 48], [752, 536, 64, 32], [1136, 160, 48, 112].

Zaczepy (indeksy0…): [624, 384], [912, 512], [1056, 368].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [144, 320] | [464, 320] | odłączony / P0 | Ustawcie końce i zasilcie. |
| 1/2 | [304, 144] | [304, 496] | odłączony / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |
| 2/1 | [624, 176] | [1040, 384] | 0 / P0 | Ustawcie końce i zasilcie. |
| 2/2 | [560, 256] | [848, 624] | 1 / P1 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |
| 3/1 | [912, 304] | [1200, 448] | 1 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [848, 400] | [1056, 624] | 2 / P1 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/aux_core_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

| Typ / ID | Obszar | Normal OFF/WARN/ACTIVE | Relaxed | Offset |
|---|---|---|---|---|
| SHUTTER/0 | [272, 272, 64, 24] | [360, 90, 60] | [420, 120, 45] | 0 |
| JAM/1 | [256, 448, 96, 96] | [360, 90, 60] | [420, 120, 45] | 0 |
| JAM/2 | [888, 256, 64, 96] | [360, 90, 60] | [420, 120, 45] | 120 |
| SHUTTER/3 | [1040, 432, 32, 96] | [390, 90, 60] | [480, 120, 45] | 0 |

Hazardy: {'id': 0, 'type': 'PULSE', 'a': [624, 176], 'radius': 48, 'phase_offset': 0}, {'id': 1, 'type': 'PULSE', 'a': [1040, 384], 'radius': 48, 'phase_offset': 30}, {'id': 2, 'type': 'PULSE', 'a': [848, 624], 'radius': 48, 'phase_offset': 90}, {'id': 3, 'type': 'SWEEP', 'a': [880, 432], 'b': [880, 600], 'travel': [144, 0], 'phase_offset': 60}.

### 9. Serce stacji — `station_heart`

Drugie pole pierwszego gracza ma środek[112,240], a jego dolna część (np.[112,272]) pozwala schronić się przed SWEEP bez opuszczania pola. Drugi dron nadal wycofuje się z PULSE. Trzy dwufazowe obwody, naprzemienne PULSE/SWEEP, przesłony i strefy przy polach. Drugi obwód wymaga skrócenia obu ramion w obrębie pól; ostatni przenosi prowadzącego zaczep na drugą stronę. Nowe zadanie: oba końce przechodzą przez różne presje, a operator zmiany zaczepu zmienia się między zadaniami. Potem wspólna ewakuacja.

Ściany `[x,y,w,h]`: [256, 368, 64, 80], [432, 192, 80, 96], [640, 176, 112, 64], [832, 128, 48, 152], [592, 480, 96, 48], [912, 640, 96, 24], [1056, 224, 64, 80].

Zaczepy (indeksy0…): [384, 320], [768, 320], [1056, 528].

| Cel/etap | P0 | P1 | Zaczep / operator | Działanie |
|---|---|---|---|---|
| 1/1 | [208, 320] | [384, 496] | 0 / P0 | Ustawcie końce i zasilcie. |
| 1/2 | [112, 272] | [384, 624] | 0 / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |
| 2/1 | [560, 320] | [768, 592] | 1 / P0 | Ustawcie końce i zasilcie. |
| 2/2 | [640, 384] | [840, 608] | 2 / P1 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |
| 3/1 | [944, 192] | [1168, 416] | 2 / P0 | Ustawcie końce i zasilcie. |
| 3/2 | [784, 144] | [1176, 560] | 1 / P0 | Po zatrzasku150 przestawcie oba końce; w razie innego zaczepu operator podchodzi i naciska E. |

P0/P1 w tabeli oznaczają wewnętrzne sloty pierwszego i drugiego gracza (interfejs: P1/P2). Pozycje to przynajmniej jedno konkretne poprawne rozwiązanie, nie teleporty ani ograniczenie ról. Należy dojść do nich korytarzami, odsunąć się przy zapowiedzi i powrócić po zagrożeniu. Kolejność dojść i realne osie ruchu są zapisane w `tests/fixtures/station_heart_success.json`; podpowiedzi autora i punkty odwrotu w `tools/map_solution_hints.json`.

| Typ / ID | Obszar | Normal OFF/WARN/ACTIVE | Relaxed | Offset |
|---|---|---|---|---|
| JAM/0 | [160, 272, 96, 96] | [360, 90, 60] | [420, 120, 45] | 0 |
| JAM/1 | [512, 272, 96, 96] | [360, 90, 60] | [420, 120, 45] | 180 |
| SHUTTER/2 | [368, 416, 32, 48] | [330, 90, 60] | [420, 120, 45] | 0 |
| SHUTTER/3 | [752, 432, 32, 64] | [360, 90, 60] | [420, 120, 45] | 0 |
| SHUTTER/4 | [1024, 448, 64, 24] | [420, 90, 60] | [480, 120, 45] | 240 |
| JAM/5 | [736, 100, 96, 96] | [360, 90, 60] | [420, 120, 45] | 120 |

Hazardy: {'id': 0, 'type': 'SWEEP', 'a': [96, 128], 'b': [96, 240], 'travel': [128, 0], 'phase_offset': 0}, {'id': 1, 'type': 'PULSE', 'a': [384, 624], 'radius': 48, 'phase_offset': 90}, {'id': 2, 'type': 'PULSE', 'a': [768, 592], 'radius': 48, 'phase_offset': 30}, {'id': 3, 'type': 'SWEEP', 'a': [880, 368], 'b': [880, 560], 'travel': [144, 0], 'phase_offset': 90}, {'id': 4, 'type': 'PULSE', 'a': [1168, 416], 'radius': 48, 'phase_offset': 90}.

## Weryfikacja i granice

Automatyczne nagrania sterują osiami, zrywem i E; nie teleportują i nie ustawiają ładunków. Testy transportu przygotowujące wynik/latch są osobnymi fixtures technicznymi, nie dowodem przejścia mapy. Aktualne54 nagrania znajdują się w `tests/fixtures/*_success.json`. Log autora `reports/levels9/recordings.log` jest uzupełniony o ostatnie6 przebiegów finału w `heart-recordings-final.log`; wszystkie konfiguracje odtworzono w `all-final.log`. Ostateczne wyniki regresji, procesowego LAN i eksportów znajdują się w PROJECT_STATUS i `reports/levels9/summary.json`.

Nie przeprowadzono ludzkiego playtestu, pomiaru subiektywnej trudności ani frajdy. Skan i nagrania są dowodem istnienia rozwiązań w sprawdzonych konfiguracjach, nie dowodem optymalności wszystkich tras ani braku każdego możliwego skrótu w przestrzeni ciągłej. Należy ocenić tempo nauki przesłon/stref, widoczność obu ramion i czy obie osoby rozumieją zmianę stanowisk.

# M11c — poziomy i współpraca: aktualna implementacja

Implementacja i automatyczny odbiór M11c ukończone na aktualnych mapach.
Końcowa ocena przez nowych graczy pozostaje do wykonania.
M12 nie rozpoczęto. Ten dokument opisuje aktualne dane i kod; zastępuje opis
wcześniejszych dziewięciu wnęk. Stan weryfikacji jest opisany oddzielnie poniżej.

## Kampania i sterowanie

Kolejność sektorów: dock → garden → reactor. W każdym celu kolejność ID0→1→2,
na ekranie1→2→3. Seed zmienia tylko fazy zagrożeń: wariant=(seed+17*sector)%3,
przesunięcie37*wariant ticków. Nie tworzy nowych map i nie zmienia kolejności celów.

LAN: każda osoba steruje swoim dronem przez WASD/strzałki, Spację(zryw), E(zaczep),
Q(ping). Host ustawia seed i trudność; obie osoby zaznaczają gotowość, host rozpoczyna.
Po sektorze obaj potwierdzają Dalej; rewanż również wymaga obu głosów.
Lokalny debug F2: P1 jak wyżej, P2 IJKL/Shift/U/O; klawisze1/2 potwierdzają sloty.
F2 zawsze zaczyna kampanię seed0/Normal. Escape/menu nie zatrzymują symulacji;
utrata fokusu zeruje wejście. Gra nie ma bota. Role w rozwiązaniach można zamieniać.

## Mechaniki i parametry

| Reguła | Implementacja |
|---|---|
| Symulacja |60 ticków/s; snapshot i wysyłanie wejścia gościa30 Hz |
| Ruch |240/s, przyspieszenie1800/s², hamowanie2400/s², collider24×24 |
| Zryw |720/s,10 ticków (do120 jednostek), cooldown90 ticków=1,5 s |
| Zryw/STUN |wyłączają zasilanie; DASH chroni przed hazardem |
| Przewód |suma długości56…720; padding kolizji3, styczność ze ścianą blokuje |
| Trafienie celu |odległość środka od odcinka≤25, po łamanej≥48 od obu końców |
| Zaczep |najbliższe gniazdo≤44, ponowne E odpina; inne zastępuje; globalny cooldown30 ticków |
| Ładowanie |+1/tick do300 (5 s prawidłowego zasilania) |
| Zanik |30 ticków grace, potem -1 co2 ticki; pierwszy ubytek przy gap32 |
| Normal / Relaxed |6 /9 wspólnej integrity;180 /240 s na sektor |
| Trafienie |ubytek1 wspólnej integrity z globalnym cooldown30; STUN12, odporność90 ticków |
| Ewakuacja |po3 celach oba środki dronów≤64 od wyjścia przez120 kolejnych ticków |
| Wynik |+1000/cel, +10*floor(pozostałe sekundy)/sektor; zwycięstwo+600*integrity |
| Porażka |integrity≤0 lub timeout; końcowy wynik=1000*ukończone cele całej kampanii |

Zdrowie/wynik przechodzą między sektorami; postęp lokalnych celów, pozycje i timery
resetują się. Zryw nie przechodzi przez ściany. Drony mogą się nakładać; nie ma
globalnego minimum kąta przewodu ani fizycznego naciągu liny. Nieaktywny przewód
nie blokuje ruchu. Zaczep tworzy trasę[P0,S,P1], bez niego[P0,P1].

## Jedyna nowa mechanika: pola stabilizacji

Cel może nie mieć pól, mieć jedną parę lub dwie pary. Każde pole ma radius44,
centra pary≥160. Każde zajmuje inny dron w NORMAL; role są zamienne. Samo
zajęcie pól nie zasila celu: musi działać zwykły przewód i trafiać cel.

W zadaniu dwufazowym para1 obowiązuje przy charge0…149. Osiągnięcie150 ustawia
trwały bit zatrzasku i aktywuje nieruchomą parę2. Od tej chwili zanik nie schodzi
poniżej150;300 kończy cel. Opuszczenie pola/zryw/STUN przerywają ładowanie ze
zwykłą grace. Jedna para nie zatrzaskuje150. Reset sektora/rewanż zerują zatrzaski.
Reguły są w objectives mapy, nie w rozgałęzieniach kodu po nazwie sektora.

Widać połączenia pól z celem, pole puste, zajęte i nieaktywne, podgląd przyszłej
pary, oznaczenie etapu, animację/napis zachowania150 i brakujący warunek w HUD.
W reduced motion pozostają trwałe oznaczenia. Komunikat jest wspólny dla LAN
oraz lokalnej gry. X blokady znajduje się na rzeczywistym kontakcie ze ścianą.

## Różnice poziomów i działania graczy

**Dock:** cel0 uczy bezpiecznego prostego przewodu bez urządzenia i pól.
Cel1: jeden gracz nad kanałem światła, drugi po prawej stronie bloku; gniazdo
prowadzi światło za narożnik. Kanał ma16 szerokości: światło6 przechodzi, dron24
nie. Na znanych stanowiskach długość przez gniazdo to648. Wspólny pobyt po prawej
stronie przekracza720, a prosta między znanymi stanowiskami trafia w ścianę.
E do S0 można użyć np. z(376,280), nie trzeba stać dokładnie na urządzeniu.
Cel2: odpiąć poprzednie gniazdo i zająć różne pola. PULSE wymaga wyboru momentu,
wycofania z lewego stanowiska i powrotu. Drugi gracz utrzymuje własne pole.

**Garden:** cel0 jest dwufazowy, początkowo bez presji podczas zmiany ustawienia.
Cel1 łączy pola z gniazdem wokół przegrody i SWEEP na północnym stanowisku;
trzeba przerwać zasilanie, uniknąć i wrócić. Cel2: po150 obie osoby zmieniają pola,
a operator przełącza S1 na S2. Po korekcie brzegów S2=(1056,512), druga para to
(776,192)/(944,624). Przegroda i inne ustawienie końców odcinają wcześniejsze obejścia.

Dwie drogi do S2 z(1104,384): krótka przecina puls(1056,432); dłuższa omija go
przez(1168,384)→(1168,576)→(1056,576)→(1056,512). Opcjonalny zryw:
z bezpiecznego(1120,448) w stronę(1056,512), dystans≈90,5<120. To konkretny
przykład, w którym zryw pomaga; nie każda prosta przez środek koła mieści się w120.

**Reactor:** cel0 rozdziela drony wokół bloku i dodaje SWEEP. Cel1 wymaga zmiany
obu stanowisk po150, z kolejnymi pulsami na końcach. Offsety0/30 dają w Normal
wspólne okno bez obrażeń210 ticków na środkach tych stanowisk. Cel2 używa najpierw
S1 (również z poprzedniego celu), potem S2. Łączy PULSE, SWEEP i ponowne ustawienie
obu graczy. Trzeci blok[784,448,48,96] i druga pozycja P1=(1168,512) odcinają
wykryte wcześniej skróty. Po zakończeniu obaj muszą dojść do wspólnego wyjścia.

Zaprojektowana progresja nie jest dowodem rosnącej subiektywnej trudności ani frajdy.

## Wszystkie układy i przykładowe rozwiązania

Współrzędne: x w prawo, y w dół; prostokąty[x,y,w,h]. Widok1280×720,
bounds[32,88,1216,600], spawny(112,592)/(176,592), wyjście(1168,592),radius64.
Poza wymienionymi ścianami teren jest otwarty. Każdy wiersz to jedna poprawna
konfiguracja geometryczna, nie lista wszystkich rozwiązań. Dojście i uniki są
zapisane osobno w nagraniach wejścia. Operator podchodzi≤44 do wybranego S,
naciska E, po czym obaj zajmują stanowiska. Po150 przechodzą do drugiego wiersza
tego celu. Jeżeli wymagany jest brak S, operator odpina poprzedni zaczep.

### dock

Cele: B0=(208,440), B1=(416,320), B2=(992,552).

Gniazda: S0=(384,320).

| Ściana ID | [x,y,w,h] |
|---|---|
| 0 | [344, 296, 24, 184] |
| 1 | [400, 272, 32, 24] |
| 2 | [432, 180, 392, 132] |
| 3 | [368, 344, 64, 136] |
| 4 | [432, 328, 392, 152] |

| Cel/etap | Pola | P0 / P1 | Zaczep / operator | Odwrót P0 / P1 |
|---|---|---|---|---|
| 0/1 | nie | (112,440) / (304,440) | brak | (112,440) / (304,440) |
| 1/1 | nie | (384,192) / (904,320) | S0 / P0 | (384,192) / (904,320) |
| 2/1 | tak | (896,552) / (1120,552) | brak | (896,648) / (1120,648) |

| Hazard ID | Typ / geometria | phase_offset |
|---|---|---|
| 0 | PULSE: (896,552),radius48 | 0 |

### garden

Cele: B0=(256,256), B1=(672,448), B2=(944,384).

Gniazda: S0=(544,448), S1=(880,384), S2=(1056,512).

| Ściana ID | [x,y,w,h] |
|---|---|
| 0 | [600, 224, 112, 160] |
| 1 | [936, 208, 96, 152] |

| Cel/etap | Pola | P0 / P1 | Zaczep / operator | Odwrót P0 / P1 |
|---|---|---|---|---|
| 0/1 | tak | (112,256) / (400,256) | brak | (112,256) / (400,256) |
| 0/2 | tak | (160,176) / (352,336) | brak | (160,176) / (352,336) |
| 1/1 | tak | (544,224) / (800,448) | S0 / P0 | (448,224) / (800,528) |
| 2/1 | tak | (880,224) / (1104,384) | S1 / P0 | (800,224) / (1168,384) |
| 2/2 | tak | (776,192) / (944,624) | S2 / P1 | (776,192) / (944,624) |

| Hazard ID | Typ / geometria | phase_offset |
|---|---|---|
| 0 | SWEEP: (480,152)→(480,296),travel(128,0) | 0 |
| 1 | PULSE: (1056,432),radius48 | 100 |

### reactor

Cele: B0=(336,448), B1=(800,320), B2=(928,496).

Gniazda: S0=(208,448), S1=(672,320), S2=(1008,592).

| Ściana ID | [x,y,w,h] |
|---|---|
| 0 | [272, 192, 112, 192] |
| 1 | [744, 136, 144, 120] |
| 2 | [784, 448, 48, 96] |

| Cel/etap | Pola | P0 / P1 | Zaczep / operator | Odwrót P0 / P1 |
|---|---|---|---|---|
| 0/1 | tak | (208,208) / (448,448) | S0 / P0 | (112,208) / (448,528) |
| 1/1 | tak | (672,160) / (1008,320) | S1 / P0 | (576,160) / (1008,416) |
| 1/2 | tak | (672,480) / (1168,320) | S1 / P0 | (576,480) / (1168,224) |
| 2/1 | tak | (672,480) / (1056,584) | S1 / P0 | (576,480) / (1120,584) |
| 2/2 | tak | (768,304) / (1168,512) | S2 / P1 | (672,304) / (1168,592) |

| Hazard ID | Typ / geometria | phase_offset |
|---|---|---|
| 0 | SWEEP: (144,144)→(144,272),travel(128,0) | 0 |
| 1 | PULSE: (672,160),radius48 | 0 |
| 2 | PULSE: (1008,320),radius48 | 30 |
| 3 | PULSE: (672,480),radius48 | 0 |
| 4 | PULSE: (1168,320),radius48 | 30 |
| 5 | PULSE: (768,304),radius48 | 0 |
| 6 | SWEEP: (944,464)→(944,624),travel(96,0) | 90 |

## Cykle i uczciwe tempo

PULSE: Normal180OFF/60TELEGRAPH/60ACTIVE (okres300), Relaxed240/90/30 (360).
SWEEP: Normal60OFF/90TELEGRAPH/180ACTIVE/30cooldown (360), Relaxed120/120/120/60 (420).
Offset skaluje się do okresu trudności, potem dochodzi37*wariant. SWEEP odwraca
kierunek co cykl. Ściany nie zasłaniają hazardu; trafienia uwzględniają kwadrat
drona i ruch w ticku. DASH daje odporność, lecz wyłącza zasilanie obu końców.

Są miejsca odwrotu, ostrzeżenia i możliwość powrotu do zadania. Nie zmieniono
prędkości, cooldownu zrywu, obrażeń ani długości ładowania. Model78 okien z
rezerwą24 ticków przed zagrożeniem i36 na ponowne ustawienie osiąga progi postępu.
To model stanowisk, nie pomiar reakcji człowieka i nie odtworzenie całej drogi.
Zbyt rozdzielone wcześniejsze fazy reaktora zastąpiono0/30, aby postęp nie znikał
za każdym razem. Nie twierdzimy, że nagrania autora wyznaczają optymalne uniki.

## Sieć i trwałość etapu

Host rozstrzyga pola i postęp. Pełny SnapshotBody protokołu2 ma108B, maskę
latched_mask:u8 przy offset37, graczy35B przy38/73. Nagłówek22B, Snapshot/Begin130B,
SessionState135B, limit1000B. Kopiowanie i kodek zachowują maskę; walidacja sprawdza
zakres, podłogę150 oraz zgodność typu celu/gniazda z mapą. Animacja nie jest źródłem
trwałego postępu. Zajęcie pól u klienta wynika z hostowego snapshotu.
Discovery zachowuje niezależną wersję1. Obie osoby potrzebują protokołu2 i tego samego content hash.

Gość przewiduje własny ruch, lecz nie rozstrzyga celów/obrażeń. Widok partnera
jest opóźniony o około6 ticków. Przy braku snapshotów>250ms gość zamraża obraz
oraz nowe komendy; cisza wiadomości>1s daje ostrzeżenie,>3s rozłączenie.
Pełne menu/remapowanie i audio nie należą do M11c.

## Faktyczna weryfikacja końcowej geometrii

- Pełna regresja: **1146PASS,0FAIL,0SKIP,19 suites,exit0**,272868ms,
  `reports/m11c/all-final.log`. Obejmuje18 sektorów i6 pełnych kampanii rzeczywistymi
  komendami bez teleportów, zwykłe/podwójne pola, role, NORMAL,149→150,zanik ireset.
- Skan brzegów:24 przypadki,3,382,821 par końców w siatce4; nie znaleziono
  obejścia bez gniazda lub z niewłaściwym. Próbkowanie nie jest dowodem ciągłym.
  Pięć dawnych konkretnych obejść ma osobne regresje w Godocie.
- Zapisane nagrania18 sektorów mają ok=true. Model78 okien ładowania osiąga progi
  z rezerwą24 ticków przed niebezpieczeństwem i36 na odzyskanie ustawienia; to model
  stanowisk, nie ludzka reakcja ani cała droga.
- Pełna kampania LAN Normal: oba procesyWON,wynik13940,integrity4.
  Relaxed: obaWON,wynik19410,integrity9. W obu maski sektorów0/5/6,
  identyczny hash i wynik/zdrowie na obu końcach. Gość nie ma Simulation.
- Skupiony test LAN w regresji odłącza odbiór pakietów na330ms: klient odzyskuje150
  i drugą parę z kolejnego pełnego snapshotu bez zdarzenia; kolejny sektor resetuje maskę.
- Widok:13 aktualnych ustawień etapów720p+13gray oraz puste pole i rzeczywista blokada.
  Podglądy są fixture prezentacji, nie dowodem przejścia. Przegląd próbek obejmuje
  końcowe Garden/Reactor, różne stany pól, grayscale i znacznik kontaktu.
- Świeży import i debug eksporty Linux/Windows:exit0. Linux boot,paraENet i natywneF2:exit0.
  Windows runtime NIE URUCHAMIANO. Odrębne katalogi/PCK: ~/.local/share/lumen-tools/m11c-smoke/.
- Manifest PASS. Wcześniejsze przebiegi przerwane na prośbę użytkownika pozostają
  historyczne; powyższe wyniki pochodzą z ukończonych ponownych przebiegów.
- Nowe duety0/5, fizyczne2komputery i runtimeWindows:NOT RUN. Nie deklarujemy oceny
  frajdy, intuicyjności, reakcji ani rosnącej trudności dla ludzi. M15/performance
  pozostaje osobną bramką. Natywny smoke nie jest benchmarkiem60 FPS.

## Źródła

`data/maps/*.json`, `data/gameplay.json`, `core/map_definition.gd`,
`core/objective_system.gd`, `core/simulation.gd`, `core/link_system.gd`,
`core/hazard_system.gd`, `core/game_snapshot.gd`, `net/packet_codec.gd`,
`app/match_session.gd`, `app/input_router.gd`, `presentation/world_view.gd`,
`presentation/link_view.gd`. Rozwiązania: `tools/map_solution_hints.json`.
Autor map/driver i nagrania nie są botem normalnej gry. Kodek/golden vectors,
regresje pól i dawnych obejść znajdują się w tests/. Logi: docs/reports/m11c/.

Build `M11c-dev`, protokół2, content SHA-256:
`15836523d54c575f2db70b76b1842f2c6f021f5e882b4dbdd331ee75438200a5`. Hash zgodnie z kontraktem obejmuje app/core/net/data; nie cały projekt.

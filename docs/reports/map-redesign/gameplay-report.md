# LUMEN LINK — raport faktycznej rozgrywki dla niezależnej oceny AI

Stan analizy: 2026-11-15, po przebudowie trzech map na wnęki przekaźników.
Raport jest samodzielny: zawiera reguły, wszystkie współrzędne rozgrywki oraz
ograniczenia dowodów. Nie wymaga przeczytania planu produkcji ani wcześniejszej rozmowy.
Analiza dotyczy źródeł projektu w `/home/pablo/lan_game`, nie starego eksportu M11.
Podczas przygotowania raportu nie zmieniano kodu, danych map ani testów.
Nie uruchamiano ponownie gry ani zestawów Godot; odczytano aktualny kod, JSON,
nagrania wejścia i istniejące wyniki. Obliczenia liczbowe wykonano poza silnikiem.

## 1. Jak rozumieć stopień pewności

- **KOD/DANE** — zachowanie lub parametr zapisany w odczytanej implementacji.
  Sam odczyt nie jest nowym testem wykonania.
- **TEST ZAPISANY** — istnieje log wcześniej wykonanego sprawdzenia; poniżej
  podano jego zakres. Raport nie przedstawia go jako testu wykonanego dziś od nowa.
- **WNIOSEK** — dedukcja z reguł/geometrii, czasem z dokładnym przykładem liczbowym.
  Nie oznacza przejścia takiej trasy przez ludzi ani odtworzenia jej w silniku.
- **NIEZBADANE** — brak odpowiedniego pomiaru albo playtestu. Nie wolno zastępować
  tej etykiety obietnicą trudności, frajdy, wymuszonej komunikacji czy balansu.

Najważniejszy stan: istnieją trzy stałe mapy i dziewięć celów w jednej kampanii.
Przekaźniki dają rzeczywistą trasę zasilania, której nie daje prosty przewód.
Jednocześnie kod pozwala dronom nakładać się na siebie, a ramionom przewodu
pokrywać się. Nie wymusza rozdzielenia graczy ani minimalnego kąta zagięcia.
Nowe mapy powtarzają tę samą konstrukcję wnęki, obróconą i przesuniętą.
Nie ma dowodu z playtestów, że to są trudne lub różnorodne zagadki.

## 2. Zawartość i przebieg sesji

**KOD/DANE.** Kampania ma niezmienną kolejność sektorów:
`dock (dok) → garden (ogród) → reactor (reaktor)`. Nie ma wyboru początkowej
mapy w menu gracza, generowania geometrii, tajnych poziomów ani dalszych sektorów.
Każdy sektor ma 2 spawny, 3 cele (`beacons`), 3 gniazda (`sockets`), 9 ścian i wyjście.
Dok ma 2 zagrożenia, pozostałe mapy po 3. Wszystkie aktualne zagrożenia to PULSE.

Normalny tryb to dwie osoby w LAN. Host ustawia seed i Normal/Relaxed; druga osoba
dołącza przez IPv4 albo listę LAN. Obaj zaznaczają gotowość, host naciska Start.
Zmiana seeda/trudności w lobby zeruje gotowość. Gra czeka na wczytanie po obu stronach,
a potem wykonuje odliczanie 180 ticków = 3 s. Nie ma bota zastępującego partnera.
Port gry domyślnie UDP 7777, discovery UDP 7778. Ten sam komputer może uruchomić
dwie instancje przez 127.0.0.1; klawiaturę odbiera wówczas okno mające fokus.

W sektorze zasila się kolejno trzy ponumerowane cele. Po trzecim obaj gracze
muszą znaleźć się w wyjściu i utrzymać ten stan przez 120 ticków = 2 s.
Po dokach i ogrodzie jest przerwa wymagająca potwierdzenia Dalej przez obie osoby.
Po reaktorze następuje zwycięstwo. Rewanż i wspólny powrót do lobby również
wymagają zgodnego wyboru obu osób. Nie ma mechaniki ratowania leżącego gracza.

W debugowym uruchomieniu F2 rozpoczyna/resetuje lokalną ekspedycję z dwoma dronami
na jednej klawiaturze, zawsze seed=0 i Normal. Nie jest to osobna mapa ani inny
zestaw reguł. F1 przełącza podgląd geometrii doków. Klawisze 1/2 potwierdzają
odpowiednie sloty między sektorami i po wyniku wyłącznie w lokalnej ekspedycji.

**KOD/DANE.** Na kolejną mapę przechodzą wspólna integralność, wynik i liczba
ukończonych celów oraz globalny tick/event ID. Resetują się pozycje dronów,
prędkości, tryby, indywidualne timery, czas sektora, cele/ładunki, zaczep i
cooldowny. Faza zagrożeń liczy się od nowego `sector_tick`, z przesunięciem wariantu.

### Warianty i seedy

`v = (seed + 17 × indeks_sektora) mod 3`, indeksy sektorów: 0,1,2.
Kolejność ID celów to `[v, (v+1) mod 3, (v+2) mod 3]`.

| Wariant | Kolejność ID celów | Numery nad ID 0 / ID 1 / ID 2 |
|---|---|---|
| 0 | 0 → 1 → 2 | 1 / 2 / 3 |
| 1 | 1 → 2 → 0 | 3 / 1 / 2 |
| 2 | 2 → 0 → 1 | 2 / 3 / 1 |

| Seed modulo 3 | dock: wariant / ID | garden: wariant / ID | reactor: wariant / ID |
|---|---|---|---|
| 0 | 0 / 0,1,2 | 2 / 2,0,1 | 1 / 1,2,0 |
| 1 | 1 / 1,2,0 | 0 / 0,1,2 | 2 / 2,0,1 |
| 2 | 2 / 2,0,1 | 1 / 1,2,0 | 0 / 0,1,2 |

Seed zmienia kolejność celów i fazę zagrożeń, a nie ściany/spawny/pozycje urządzeń.
W zakresie tych reguł są trzy klasy seeda. Dwa poziomy trudności dają sześć
kombinacji kampanii i 18 izolowanych kombinacji sektor/wariant/trudność.
Nie są to 18 różnych układów map.

## 3. Sterowanie rzeczywiście podłączone do gry

| Akcja | LAN: każdy gracz na swoim komputerze / lokalny P1 | Lokalny P2 w F2 | Pad w routerze podstawowym |
|---|---|---|---|
| Ruch | WASD lub strzałki | IJKL | lewy drążek |
| Zryw | Spacja | Shift | przycisk indeks 0 |
| Przełączenie gniazda | E | U | przycisk indeks 2 |
| Ping w swojej pozycji | Q | O | przycisk indeks 3 |
| Menu | Escape | wspólne Escape | patrz ograniczenie poniżej |

**KOD/DANE.** Router usuwa auto-repeat klawiatury. Akcje dash/anchor/ping są
zboczami naciśnięcia, utrzymanie przycisku nie ponawia ich. Po nieudanej próbie
trzeba puścić i nacisnąć ponownie. Ruch jest kwantowany do osi -127…127,
a wektor po przekątnej ograniczany do długości 1. Drążek ma deadzone 0,2 z
przeskalowaniem pozostałego zakresu do 0…1; sumuje się z klawiaturą i jest ograniczany.

Menu i utrata fokusu zerują wejście, ale **nie zatrzymują symulacji**, czasu ani
zagrożeń. Wyhamowanie z normalnej prędkości nie jest natychmiastowym zatrzymaniem.
Odliczanie także nie przyjmuje ruchu. W LAN oba komputery korzystają z routera
slotu wejścia 0; gość nie gra przez IJKL. Numery slotów sieciowych to osobna rzecz.

W `project.godot` przycisk pada indeks 6 jest przypisany do `ui_cancel`, jednak
obsługa menu w AppRoot przechwytuje konkretnie zdarzenie klawiatury Escape w
`_unhandled_key_input`. Z samych bindingów nie wynika działające menu na padzie.
Pełna nawigacja padem nie została tu potwierdzona. `InputRouter.configure`
przyjmuje ustawienia, ale ich bindingów nie stosuje: runtime remapowanie nie działa.

Ping ma osobny cooldown 60 ticków = 1 s na gracza, jest markerem w pozycji drona,
pozostaje widoczny 90 ticków = 1,5 s. Nie steruje partnerem ani nie aktywuje celu.
Ping/anchor blokuje STUN; sam DASH nie blokuje ich przyjęcia. Zryw podczas STUN
jest odrzucony przez Movement. Akcja odrzucona w cooldownie nie czeka w kolejce.

## 4. Ruch, kolizja i zryw

Współrzędne są jednostkami świata odpowiadającymi pikselom widoku bazowego 1280×720.
Symulacja wykonuje 60 kroków/s (dt=1/60), niezależnie od liczby renderowanych klatek.

| Parametr | Faktyczna wartość |
|---|---|
| Normalna prędkość | 240 jednostek/s; przy pełnej prędkości 4 jednostki/tick |
| Przyspieszenie | 1800 jednostek/s²; zmiana prędkości do 30/tick |
| Hamowanie przy braku osi | 2400 jednostek/s²; do 40/tick |
| Collider drona | kwadrat osiowy 24×24, half-size 12; obrót grafiki go nie obraca |
| Kolizje | dron–ściana i granice planszy; ślizganie wzdłuż ścian; swept AABB |
| Dron–dron | brak: drony przenikają i mogą zajmować identyczną pozycję |
| Zryw | prędkość 720/s, 10 ticków ≈ 0,167 s, do 120 jednostek bez przeszkód |
| Cooldown zrywu | 90 ticków = 1,5 s od rozpoczęcia |
| Kierunek zrywu | bieżąca oś, jeśli niezerowa; inaczej ostatni facing, początkowo w prawo |

Zryw nie przenika ścian. Podczas niego kierunek jest utrzymany; po zakończeniu
prędkość zostaje ograniczona do 240, a potem działa normalny ruch.
W trakcie DASH dron ignoruje obrażenia od hazardów, lecz przewód całej pary jest
nieaktywny. Nie trzeba utrzymywać aktywnego przewodu, żeby chodzić: za duża długość,
ściana lub zajęty dron nie ciągną partnera, nie ograniczają ruchu i same nie zadają obrażeń.

Kolejność kroku Simulation: zmniejszenie timerów → ping/socket → nowe zrywy → ruch
obu graczy → trafienia hazardów → porażka przy integrity≤0 → ocena przewodu →
ładowanie celu → ekstrakcja/limit czasu. Ma to znaczenie dla zrywu na ostatni moment,
globalnego cooldownu obrażeń i priorytetu śmierci nad ekstrakcją.

## 5. Przewód i przekaźniki — dokładna reguła

Bez zaczepu punkty przewodu to `[P0,P1]`. Z zaczepem `[P0,S,P1]`.
Aktywne jest co najwyżej jedno wspólne gniazdo z trzech. Przewód nie owija się
sam wokół ścian, nie zapamiętuje poprzednich zaczepów i nie jest fizyczną liną.

E/U wybiera najbliższe gniazdo w odległości **≤44 od środka drona**.
Przy remisie zostaje pierwsze w tablicy (mapy sortują ID rosnąco).
Aktywne gniazdo zostaje odpięte; inne zastępuje dotychczasowe.
Przełączenie ma wspólny cooldown 30 ticków = 0,5 s. Przy dwóch akcjach w jednym
ticku pierwszy jest slot0 w ticku parzystym, slot1 w nieparzystym; druga akcja
trafia już na cooldown. Brak gniazda w zasięgu nie kosztuje ładunku/zdrowia i nie
ustawia cooldownu. Wybór sprawdza odległość, nie widoczność urządzenia.
Nie trzeba trzymać E ani stać przy urządzeniu po włączeniu.

Długość jest sumą długości odcinków. Przewód ACTIVE wymaga jednocześnie:

1. Oba drony w trybie NORMAL (ani DASH, ani STUN).
2. Łączna długość od **56 do 720**, włącznie.
3. Żaden odcinek nie przecina ściany ani granicy planszy z paddingiem 3.
   Dotknięcie styczne również blokuje. Odpowiada to szerokości kolizyjnej 6.

Statusy mają priorytet: PLAYER_BUSY → TOO_SHORT → TOO_LONG → OCCLUDED → ACTIVE.
Dlatego np. zbyt długi i zasłonięty przewód może pokazać wyłącznie „za daleko”.
Limit 720 dotyczy całej drogi przez gniazdo, a nie każdego ramienia oddzielnie.

### Co faktycznie znaczy „przewód przechodzi przez cel”

`hits_beacon` dla każdego odcinka wyznacza najbliższy środkowi celu punkt Q.
Musi zachodzić odległość Q–cel ≤25, a długość po łamanej od P0 do Q oraz
od Q do P1 musi wynosić co najmniej 48 z każdej strony. Wystarczy jeden taki
odcinek. Ładowanie używa tej próbki geometrycznej w ticku, nie historii przejścia
wiązki pomiędzy tickami. Stanie dokładnie na celu nie jest samo w sobie warunkiem
sukcesu ani zakazem; rozstrzyga całe wyrażenie. Aktywny przewód długości np. 60
nie może zasilać celu, bo nie pomieści dwóch marginesów 48 (potrzeba ≥96).

Liczone jest **arclength po łamanej**, także gdy ramiona się nakładają lub
zawracają tą samą drogą. Nie ma ograniczenia kąta, odległości P0–P1, testu
samoprzecięcia, wymagania różnych stron celu ani warunku, że oba ramiona
oddzielnie muszą go trafić. To ważne dla oceny wymaganej współpracy (sekcja 10).

## 6. Cele, czas, zwycięstwo i wynik

| Mechanika | Reguła implementacji |
|---|---|
| Aktywny cel | tylko ID wskazane przez objective_order[objective_index] |
| Ładowanie | +1/tick prawidłowego zasilania; próg 300 = 5 s ciągłego zasilania |
| Przerwa w zasilaniu | 30 ticków bez ubytku; potem -1 w tickach z parzystym odstępem od ostatniego zasilania |
| Tempo zaniku | po grace około 30 jednostek/s, połowa tempa ładowania |
| Ukończony cel | zatrzaskuje bit complete_mask; nie wymaga dalszego podtrzymania |
| Kilka celów naraz | tylko bieżący; następny najwcześniej w następnym ticku |
| Ekstrakcja | 3 ukończone cele, oba środki dronów w promieniu ≤64 od (1168,592), 120 kolejnych ticków |
| Przerwanie ekstrakcji | opuszczenie promienia przez dowolny dron zeruje postęp |
| Wymóg aktywnej wiązki przy wyjściu | brak; tryb DASH/STUN sam w sobie też nie wyklucza ekstrakcji |
| Normal | 6 wspólnej integrity na start kampanii, 180 s na każdy sektor |
| Relaxed | 9 wspólnej integrity, 240 s na każdy sektor |
| Porażka | wspólna integrity≤0 lub czas sektora wyzerowany |

Dla konkretnego wzoru zaniku: pierwszy ubytek po ostatnim zasilaniu jest przy
odstępie 32 ticków (gap>30 i gap%2==0). Pełna utrata 300 jednostek od pełnego
niezatrzaśniętego ładunku wymagałaby 630 ticków od ostatniego zasilania.
Ukończony cel faktycznie nie zanika, ponieważ system już go nie wybiera.
Nie ma regeneracji zdrowia pomiędzy sektorami.

Każdy cel daje +1000. Ukończenie sektora dodaje `10 × floor(remaining_ticks/60)`.
Zwycięstwo po reaktorze dodaje dodatkowo `600 × pozostała integrity`.
Przy porażce finalny wynik jest nadpisywany na `1000 × liczba ukończonych celów
w całej kampanii`, bez wcześniejszych premii czasu. Samo nietrafienie celu lub
przełączenie socketu nie odejmuje punktów. Rekordy zapisują się lokalnie.

Ekstrakcja w ostatnim dostępnym ticku ma pierwszeństwo przed timeoutem, ale
śmiertelne obrażenia tego ticku kończą grę przed ekstrakcją. Testy tych granic
istnieją w `test_hazards.gd`; używają specjalnie zmodyfikowanej mapy testowej,
nie dowodzą obecności hazardu przy wyjściu na mapie produkcyjnej.

## 7. Układy wszystkich map

**DANE.** Oś X rośnie w prawo, Y w dół. Prostokąty poniżej to `[x,y,szerokość,wysokość]`.
Wspólne bounds: `[32,88,1216,600]`, czyli obszar do x=1248, y=688.
Fizyczny środek drona jest odsunięty od granic o 12 (około x=44…1236, y=100…676).
Wspólne spawny: P0=(112,592), P1=(176,592). Wyjście: środek (1168,592), promień 64.
Przestrzeń poza wymienionymi ścianami jest otwarta; tekstura tła nie tworzy kolizji.

### Wspólna konstrukcja wnęki — istotna dla wszystkich dziewięciu celów

W lokalnych współrzędnych wnęki tył jest przy x=0, wejście przy x=80.
Wnętrze ma szerokość 48 (y od -24 do +24). Ściany: tył `[-24,-48,24,96]`,
góra `[0,-48,80,24]`, dół `[0,24,80,24]`. Gniazdo jest w (16,0), cel w (48,0).
Całość ma w obrysie 104×96 przed obrotem. Każda z dziewięciu wnęk jest kopią
tego układu z obrotem o wielokrotność 90° i translacją. Szczelina dla środka
drona pomiędzy bocznymi ścianami ma szerokość 24; dla osi przewodu z paddingiem3 — 42.

Schemat bez zachowania skali, otwór po prawej:

```text
        ściana boczna
    ┌─────────────────┐
 tył│ S──32──B        · wejście       P0
    │                 ·             /
    └─────────────────┘            /   dwa ramiona prowadzą do S
        ściana boczna                  P1
S = gniazdo, B = cel; P0 i P1 to końce przewodu, nie węzły trasy ścian.
```

Znany układ z narzędzia autora: jeden gracz dochodzi do lokalnego (48,0),
przełącza gniazdo oddalone o 32; następnie drony kończą w (144,-32) i (144,+32).
Ramiona przechodzą przez wspólny otwór do gniazda. Każde ma ≈131,94, suma≈263,88;
odległość osi ramienia od środka celu≈7,76, więc mieści się w promieniu 25.
To jest jedna znana konfiguracja, nie zbiór wszystkich rozwiązań.

Kolumna „otwór” oznacza kierunek od tyłu wnęki na zewnątrz. Wejście do wnęki
z tego kierunku oznacza ruch przeciwnie do strzałki, np. otwór →: podchodzimy od prawej.
ID w tabelach są zerowe; numer wyświetlany 1/2/3 zależy od wariantu (sekcja 2).

### Dok — `dock`, sektor 1

| ID celu/gniazda | Cel B | Gniazdo S | Otwór | Znane końce P0 / P1 |
|---|---|---|---|---|
| 0 | (368,256) | (336,256) | → prawo | (464,224) / (464,288) |
| 1 | (640,240) | (640,208) | ↓ dół | (672,336) / (608,336) |
| 2 | (912,416) | (944,416) | ← lewo | (816,448) / (816,384) |

Wszystkie ściany kolizyjne:

| ID ściany | Prostokąt [x,y,w,h] | Wnęka celu ID |
|---|---|---|
| 0 | [296, 208, 24, 96] | 0 |
| 1 | [320, 208, 80, 24] | 0 |
| 2 | [320, 280, 80, 24] | 0 |
| 3 | [592, 168, 96, 24] | 1 |
| 4 | [664, 192, 24, 80] | 1 |
| 5 | [592, 192, 24, 80] | 1 |
| 6 | [960, 368, 24, 96] | 2 |
| 7 | [880, 440, 80, 24] | 2 |
| 8 | [880, 368, 80, 24] | 2 |

Wszystkie hazardy (PULSE, promień48):

| ID | Środek | phase_offset w danych |
|---|---|---|
| 0 | (560,560) | 0 |
| 1 | (864,192) | 100 |

**Opis przestrzenny z danych:** Wnęka0 leży w lewej górnej części, wnęka1 wyżej pośrodku, wnęka2 po prawej niżej. Zewnętrzne ustawienia zmieniają stronę: prawa → dolna → lewa dla wariantu0. Jeden puls leży na dolnej trasie przez środek, drugi w górnej prawej części. Oba można ominąć; nie tworzą zamkniętej bramy do celu.

### Ogród — `garden`, sektor 2

| ID celu/gniazda | Cel B | Gniazdo S | Otwór | Znane końce P0 / P1 |
|---|---|---|---|---|
| 0 | (320,256) | (320,288) | ↑ góra | (288,160) / (352,160) |
| 1 | (688,304) | (656,304) | → prawo | (784,272) / (784,336) |
| 2 | (1008,288) | (1008,256) | ↓ dół | (1040,384) / (976,384) |

Wszystkie ściany kolizyjne:

| ID ściany | Prostokąt [x,y,w,h] | Wnęka celu ID |
|---|---|---|
| 0 | [272, 304, 96, 24] | 0 |
| 1 | [272, 224, 24, 80] | 0 |
| 2 | [344, 224, 24, 80] | 0 |
| 3 | [616, 256, 24, 96] | 1 |
| 4 | [640, 256, 80, 24] | 1 |
| 5 | [640, 328, 80, 24] | 1 |
| 6 | [960, 216, 96, 24] | 2 |
| 7 | [1032, 240, 24, 80] | 2 |
| 8 | [960, 240, 24, 80] | 2 |

Wszystkie hazardy (PULSE, promień48):

| ID | Środek | phase_offset w danych |
|---|---|---|
| 0 | (496,528) | 0 |
| 1 | (816,448) | 100 |
| 2 | (1008,464) | 200 |

**Opis przestrzenny z danych:** Pierwsza wnęka otwiera się ku górze w lewej części, druga w prawo w środku, trzecia w dół po prawej. Dwa pulsy leżą niżej niż urządzenia, trzeci pod prawym celem. Układ zwiększa liczbę niebezpiecznych obszarów względem doków, lecz nie dodaje innego typu zagadki.

### Reaktor — `reactor`, sektor 3

| ID celu/gniazda | Cel B | Gniazdo S | Otwór | Znane końce P0 / P1 |
|---|---|---|---|---|
| 0 | (304,256) | (336,256) | ← lewo | (208,288) / (208,224) |
| 1 | (688,256) | (688,224) | ↓ dół | (720,352) / (656,352) |
| 2 | (944,400) | (944,432) | ↑ góra | (912,304) / (976,304) |

Wszystkie ściany kolizyjne:

| ID ściany | Prostokąt [x,y,w,h] | Wnęka celu ID |
|---|---|---|
| 0 | [352, 208, 24, 96] | 0 |
| 1 | [272, 280, 80, 24] | 0 |
| 2 | [272, 208, 80, 24] | 0 |
| 3 | [640, 184, 96, 24] | 1 |
| 4 | [712, 208, 24, 80] | 1 |
| 5 | [640, 208, 24, 80] | 1 |
| 6 | [896, 448, 96, 24] | 2 |
| 7 | [896, 368, 24, 80] | 2 |
| 8 | [968, 368, 24, 80] | 2 |

Wszystkie hazardy (PULSE, promień48):

| ID | Środek | phase_offset w danych |
|---|---|---|
| 0 | (496,464) | 0 |
| 1 | (800,352) | 100 |
| 2 | (1040,192) | 200 |

**Opis przestrzenny z danych:** Wnęka0 otwiera się w lewo, środkowa w dół, prawa dolna ku górze. Pulsy leżą w dolnej lewej części środka, pośrodku z prawej i wysoko po prawej. Nie ma ruchomej bariery SWEEP ani specjalnego finałowego celu. Zwycięstwo wynika z indeksu trzeciego sektora, nie z dodatkowej mechaniki reaktora.

## 8. Dlaczego wnęki wymagają przekaźnika i co ten dowód obejmuje

**WNIOSEK GEOMETRYCZNY**, wsparty sprawdzeniem konstrukcji ścian i wybranych
konfiguracji w zapisanych testach. Nie jest to statystyczny dowód odkrywalności zagadki.

Cel w lokalnym (48,0) jest oddalony od wejścia x=80 o 32, więcej niż promień
trafienia25. Odcinek trafiający cel i nieprzecinający ścian musi więc wejść do
wnęki. Prosta nie może wejść i wyjść przez ten sam otwór bez zawracania; pozostałe
trzy strony są zamknięte. Co najmniej jeden koniec prostego przewodu musi być
wewnątrz. Fizyczny środek takiego drona ma x∈[12,80], y∈[-12,12]. Odległość od
celu jest najwyżej sqrt(36²+12²)≈37,95. Rzut środka celu na odcinek nie może być
od tego końca dalej niż sam środek celu, więc nie spełnia wymaganego marginesu48.
Ten argument dotyczy fizycznie dostępnych pozycji dronów, a nie teleportów w ściany.

Przez dodanie gniazda trasa zawraca we wnęce. Punkt najbliższy celowi może być
≥48 od obu końców **po długości łamanej**, choć fizycznie wszystko mieści się blisko.
Nie ma bramki „ID gniazda musi równać się ID celu”; dopasowanie wynika z geometrii.
Na znanych końcach właściwe gniazdo działa, dwa inne nie działają. Test ten nie
przeszukuje wszystkich możliwych położeń obu dronów przy każdym błędnym gnieździe.
Nie wolno na tej podstawie twierdzić, że udowodniono jedyność wszystkich rozwiązań.

## 9. Zagrożenia i wspólna integralność

### PULSE obecne na mapach

**KOD/DANE.** Każdy puls jest statycznym kołem promienia48, działa tylko w fazie
ACTIVE. Nie strzela pociskiem. Obrażenia sprawdzają ruchomy kwadrat drona na
jego rzeczywistej drodze w ticku (swept collision), nie tylko punkt końcowy.
Kontakt zależy od przecięcia koła z kwadratem24×24: na osi zagrożenie sięga do
60 od środka drona; w pobliżu narożników test jest zaokrąglony, nie jest prostym
kwadratem promienia60 ani wyłącznie kołem promienia60.
Ściany nie zasłaniają hazardu w `HazardSystem.hits`; nie ma testu line-of-sight.
Sam przewód nie otrzymuje obrażeń od pulsu i puls nie wyłącza go bez trafienia drona.

| Faza PULSE | Normal | Relaxed |
|---|---|---|
| OFF, bez obrażeń | 180 ticków / 3 s | 240 / 4 s |
| TELEGRAPH, ostrzeżenie bez obrażeń | 60 / 1 s | 90 / 1,5 s |
| ACTIVE | 60 / 1 s | 30 / 0,5 s |
| Okres | 300 / 5 s | 360 / 6 s |

Dla PULSE indeks cyklu to:
`(sector_tick + floor(phase_offset × okres / 300) + 37 × wariant) mod okres`.
NORMAL: offsety 0/100/200 pozostają 0/100/200; RELAXED: 0/120/240.
Wariant dodaje 0/37/74 ticki. Z tego powodu nie wszystkie pulsy są jednocześnie
w OFF na początku sektora. Podczas 3-sekundowego odliczania `sector_tick` nie rośnie.

Przykład startowych faz przy sector_tick=0, wariancie0: offset0 OFF, offset100 OFF;
offset200 w Normal już TELEGRAPH, w Relaxed TELEGRAPH od pierwszego ticku tej fazy.
Faza i czas są deterministyczne; nie ma losowania okresu każdego urządzenia.

### Trafienie

Trafienie niechronionego drona ustawia STUN na12 ticków (0,2 s), zeruje prędkość
i nadaje indywidualną odporność na90 ticków (1,5 s). W STUN ignoruje on ruch,
nie rozpocznie zrywu ani nie użyje gniazda/pingu. STUN wyłącza przewód całej pary.
Odporność po trafieniu sama w sobie nie wyłącza przewodu po ustaniu STUN.

Wspólny damage_cooldown trwa30 ticków (0,5 s). Pierwsze trafienie poza cooldownem
odejmuje1 wspólnej integrity. Inny dron trafiony w tym samym ticku także dostaje
STUN i odporność, ale nie odejmuje drugiego punktu. Trafienie podczas globalnego
cooldownu nadal może ogłuszyć drona bez dodatkowego ubytku wspólnego zdrowia.
DASH i indywidualna odporność powodują pominięcie trafienia. Nie ma osobnych
pasków zdrowia, leczenia, odrodzenia na środku mapy ani kosztu punktowego za sam zryw.

### SWEEP: zaimplementowane, ale niewykorzystane w obecnych poziomach

Kod obsługuje poruszający się osiowo odcinek z `a,b,travel`, szerokością10
(collider drona uwzględniony przez grow17) i naprzemiennym kierunkiem cyklu.
Normal: OFF60, TELEGRAPH90, ACTIVE180, cooldown30, razem360 ticków = 6 s.
Relaxed: OFF120, TELEGRAPH120, ACTIVE120, cooldown60, razem420 = 7 s.
Zachowanie ma testy jednostkowe, ale **żaden aktualny JSON mapy nie zawiera SWEEP**.
Nie należy opisywać go jako wyzwania napotykanego w obecnej kampanii.

## 10. Faktycznie wymagana współpraca i jej granice

### Co wynika z implementacji

Obie osoby sterują końcami jednej trasy światła. Działanie celu wymaga prawidłowej
łącznej geometrii oraz NORMAL u obu graczy. Zryw lub ogłuszenie jednego przerywa
zasilanie. Każdy może zmienić wspólny zaczep i tym samym zepsuć lub poprawić trasę
partnera. Zdrowie i wynik są wspólne. Obaj muszą dojść do wyjścia oraz zatwierdzić
przejście. To są realne zależności kooperacyjne zapisane w kodzie.

Znana, przetestowana trasa ustawia obu graczy na zewnątrz kolejnej wnęki,
a sockety przełącza wyłącznie slot0. Nie ma przypisanych ról typu „jeden operuje
panelami, drugi zasila” ani zadań dostępnych tylko dla jednego drona.
Różne grafiki dronów nie oznaczają różnych zdolności ruchu.

### Ważny kontrprzykład: oba drony w jednym punkcie

**WNIOSEK Z KODU I OBLICZEŃ, NIE NOWY REPLAY GODOT.** Lokalnie ustawiamy oba
normalne drony w P=(144,0), socket S=(16,0), cel B=(48,0).
Jest to fizycznie wolna pozycja na zewnątrz wnęki. Trasa `[P,S,P]` ma długość256.
Oba odcinki są wolne od ścian i biegną dokładnie po sobie. Na pierwszym odcinku
punkt B ma odległość96 od P0 po przewodzie, a do P1 pozostaje160. Zatem spełnia
promień25 i oba marginesy48. Brak kolizji dron–dron dopuszcza taki układ.

Przykład dla doku/ID0: **P0=P1=(464,256), S=(336,256), B=(368,256)**.
Wszystkie wnęki są kopiami, więc to samo rozumowanie obraca się i przesuwa.
Przedtem któryś dron musi znaleźć się w zasięgu44, żeby włączyć gniazdo;
samo powyższe ustawienie nie włącza go zdalnie. Po aktywacji oba mogą znów chodzić razem.

Wynik analizy: nie ma gwarancji rozdzielenia graczy, dwóch odrębnych ramion,
minimalnego kąta ani przeciwnych stron celu. Wizualne „V” to znane rozwiązanie,
a nie wymóg. Przekaźnik daje zawrócenie trasy, ale może być obsłużony schematem
„podejdź → E → wyjdź razem na oś wnęki”. Jest to potencjalne uproszczenie
zagadki wynikające z reguł; jego rzeczywistą łatwość/odkrywalność należy zbadać.

### Drugi kontrprzykład: jeden dron pozostaje na celu

**WNIOSEK**, także bez nowego wykonania w silniku. Lokalnie P0=B=(48,0),
S=(16,0), P1=(144,32). Pierwszy odcinek ma długość32, drugi≈131,94.
Na drugim odcinku punkt najbliższy B jest ≈7,76 od B; jego położenie po całej
łamanej to ≈63,04 od P0 i ≈100,89 od P1. Zatem `hits_beacon` zwracałby true,
choć pierwszy koniec leży dokładnie na celu. Oba odcinki mieszczą się w otworze.
Wynika to z ponownego przejścia w pobliżu celu po zawróceniu przy S.

Test „parkowanie na przekaźniku nie działa” dotyczy P0=S, a nie P0=B.
Nie potwierdza wcześniejszej silniejszej tezy, że obaj muszą wycofać się z wnęki.
Wymóg zmiany ustawienia obu graczy między wszystkimi celami nie został
formalnie udowodniony; nagrania pokazują jedną trasę, w której obaj się przemieszczają.

### Różnorodność i nacisk czasowy

**KOD/DANE:** dziewięć kopii tego samego kształtu; inne rozmieszczenie, otwory,
kolejność i rozłożenie pulsów. Nie ma drzwi przełączanych socketami, ruchomych
celów, celów wymagających kilku gniazd naraz, czasowych podtrzymań ukończonych
urządzeń ani odmiennych reguł finału. Każdy przekaźnik pozostaje aktywny bez limitu czasu.

**WNIOSEK:** po rozpoznaniu pierwszej wnęki pozostałe mogą być głównie
powtórzeniem dojścia i ustawienia. Hazardy można ominąć — znane nagrania
unikają ich przez cały czas, nie używają zrywu, nie tracą integrity i są znacznie
krótsze od limitów. Nie dowodzi to, że nowi gracze przejdą je szybko.
Zwiększona liczba pulsów w dalszych mapach nie dowodzi rosnącej trudności.

## 11. Informacja dla gracza i sieć mające znaczenie dla rozgrywki

**KOD.** Nad celami są numery1/2/3 według wariantu; pierścień postępu ma promień18,
a reguła trafienia promień25. Grafika urządzenia nie jest colliderem celu.
Gniazdo zmienia teksturę po aktywacji. Aktywny przewód ma jasny rdzeń i halo;
nieaktywny jest kreskowany. OCCLUDED dodaje czerwony znak X w połowie pomiędzy
końcami, niekoniecznie dokładnie w punkcie przecięcia ściany. TOO_SHORT/TOO_LONG
mają żółty marker odległości. Wizualne halo szerokości16 nie jest szerokością
kolizyjną6. Ozdobne kreski podłogi między gniazdem a celem nie przenoszą energii.

PULSE ostrzega żółtym okręgiem i kreskami, a aktywny pokazuje czerwony obszar,
obrys i wykrzyknik. Nie jest to wyłącznie różnica koloru. HUD podaje integralność,
liczbę celów, czas, wynik, sektor i odliczanie. Lokalny debug wyświetla również
przyczynę nieaktywności i komunikat „podejdź bliżej przekaźnika” przez45 ticków;
HUD LAN nie ma tego samego tekstowego wyjaśnienia przyczyny ani tej podpowiedzi.
Nie należy zakładać gotowego samouczka tylko dlatego, że w SettingsData jest `hints`.

Animacje zrywu, trafienia i FX są prezentacją; nie powiększają colliderów i nie
naliczają zasilania. Reduced motion oraz Low ograniczają prezentację. Nie ma
podłączonego systemu audio w analizowanym runtime, mimo pól głośności w ustawieniach.
Pełny ekran ustawień/remapowania i rozbudowany samouczek nie wynikają z obecnego kodu.

Host rozstrzyga ruch, obrażenia, cele i wynik przy60 Hz. Snapshoty i wysyłanie
wejścia gościa są co drugi tick (30 Hz). Lokalny F2 również próbkuje wejście co
dwa ticki; host LAN dostaje nową lokalną komendę na tick. Gość przewiduje własny
ruch/zryw ze statyczną kolizją i przyjmuje korekty; nie rozstrzyga lokalnie obrażeń
ani ładowania. Partner u gościa jest renderowany około6 ticków (100 ms) za
estymowanym czasem hosta, z maksymalną ekstrapolacją6 ticków. Dlatego wyświetlana
geometria przewodu i autorytatywne zasilanie mogą chwilowo nie pokrywać się idealnie.

Brak snapshotu przez >250 ms zatrzymuje generowanie nowych komend gościa i zamraża
jego obraz. Cisza wiadomości >1 s daje „słabe połączenie”, >3 s rozłącza sesję.
Host przy brakujących komendach utrzymuje poprzednią oś maksymalnie6 ticków,
potem ją zeruje. Brak reconnect i przejęcia roli hosta po jego odejściu.
Są testy sieci lokalnej i awarii; nie dowodzi to jakości wszystkich domowych sieci.

## 12. Co faktycznie sprawdzono — odczyt istniejących artefaktów

Główny log: `docs/reports/map-redesign/all-final.log`.
Odczytano końcowy JSON: **1119 PASS, 0 FAIL, 0 SKIP, 17 suites, exit0,
97357 ms**. To zestaw asercji technicznych, nie 1119 osobnych ludzkich przejść.
Wcześniejszy `all.log` ma1 FAIL starego testu położenia ściany; miarodajny jest
późniejszy `all-final.log` po dostosowaniu testu do nowej geometrii.

| Dowód | Potwierdza | Nie potwierdza |
|---|---|---|
| test_relay_puzzles | dla9 wybranych ustawień poprawny socket zasila; brak socketu i dwa inne nie zasilają; końcówka na socket nie wystarcza | jedyności rozwiązania, braku nakładania ramion, konieczności rozdzielenia graczy |
| geometry.log + check_relay_geometry | wszystkie9 zestawów prostokątów odpowiada konstrukcji wnęki; na3 ruchowych trasach wariantu0 z wyzerowanymi anchor nie rośnie żaden ładunek | przeszukania wszystkich trajektorii; same próby negatywne nie są uniwersalnym dowodem |
| test_simulation, 18 nagrań | rzeczywiste InputCommand kończą każdy sektor/wariant/trudność, bez teleportowania i bez wymuszenia celów | trudności, zrozumiałości bez instrukcji, potrzeby zrywu |
| test_simulation, 6 kampanii | wszystkie sektory z zachowaniem stanu kończą się WON i9 celami | sześciu nowych duetów ludzkich ani sześciu fizycznych konfiguracji sieci |
| test_flow | przepływ aplikacji: loading, countdown, cele, zmiany map, głosy, wyniki i zapis | całej rozgrywki każdej konfiguracji na dwóch fizycznych komputerach |
| 9 PNG i render.log | narzędzie natywnego OpenGL wygenerowało9 podglądów ustawień | obrazy są fixture prezentacji, nie zapisem samodzielnego przejścia graczy |
| content-final.log | schemat, bezpieczeństwo i flood-fill map; wymiary/licencje assetów | flood-fill sam w sobie nie dowodzi rozwiązywalności przewodu |

Próby bez anchor odtwarzały tylko wariant0 na każdej z map, odpowiednio1629/1676/1692
ticki. Szersze wykluczenie prostej linii jest wnioskiem geometrycznym z sekcji8,
nie efektem zbadania wszystkich możliwych ruchów. Konstrukcja wnęki jest niezależna
od wariantu i trudności.

### Zapisane czasy przejścia sektorów

Każde nagranie zaczyna od PLAYING bez odliczania, kończy po ekstrakcji120 ticków.
Każda mapa jest tu izolowana przez `Simulation.initialize`, z indeksem sektora0,
więc również izolowany reaktor kończy się INTERMISSION. Dopiero prawdziwa kampania
ustawia jego indeks2 i kończy się WON. Integralność w tabeli to stan na końcu.
Slot0 używa trzech kolejnych seriali anchor; slot1 nie używa anchor w żadnym z
18 nagrań. Zryw i ping mają serial0. Narzędzie zna pozycje rozwiązania z góry,
używa siatki8 i omija całe obszary hazardów. Nie jest modelem zachowania nowicjusza.

| Mapa | Wariant | ID celów | Ticki (Normal / Relaxed) | Sekundy | Integrity (Normal / Relaxed) | Wynik izolowanego sektora (N / R) |
|---|---|---|---|---|---|---|
| dock | 0 | 0,1,2 | 1629 / 1629 | 27.15 | 6 / 9 | 4520 / 5120 |
| dock | 1 | 1,2,0 | 1879 / 1879 | 31.32 | 6 / 9 | 4480 / 5080 |
| dock | 2 | 2,0,1 | 1836 / 1836 | 30.60 | 6 / 9 | 4490 / 5090 |
| garden | 0 | 0,1,2 | 1676 / 1676 | 27.93 | 6 / 9 | 4520 / 5120 |
| garden | 1 | 1,2,0 | 2058 / 2058 | 34.30 | 6 / 9 | 4450 / 5050 |
| garden | 2 | 2,0,1 | 2068 / 2068 | 34.47 | 6 / 9 | 4450 / 5050 |
| reactor | 0 | 0,1,2 | 1692 / 1692 | 28.20 | 6 / 9 | 4510 / 5110 |
| reactor | 1 | 1,2,0 | 2179 / 2179 | 36.32 | 6 / 9 | 4430 / 5030 |
| reactor | 2 | 2,0,1 | 2104 / 2104 | 35.07 | 6 / 9 | 4440 / 5040 |

Normal i Relaxed w tych nagraniach mają identyczne czasy, ponieważ automat omija
zagrożenia zamiast czekać na ich fazy. Różnica wyniku wynika z dłuższego limitu czasu
Relaxed. Żaden z tych czasów nie jest wynikiem playtestu ani prognozą czasu nowego duetu.

### Czego nie wykonano lub nie wykazano

- Nowe duety: **0/5, NOT RUN**, zgodnie z aktualną macierzą manualną.
  Brak dowodu spełnienia celu „4 z5 duetów zasila pierwszy cel w90 s bez pomocy”.
- Brak ręcznej oceny wszystkich18 kombinacji na aktualnych wnękach.
- Brak nowego replay silnika dla dwóch kontrprzykładów z sekcji10.
- Brak pomiaru, czy niewłaściwe wybory przekaźników są sensownymi alternatywami,
  czy tylko łatwo odrzucanymi urządzeniami przy odległych celach.
- Brak dowodu rosnącej trudności dock→garden→reactor, konieczności zrywu,
  wymuszonego rozdzielenia dronów i bogatej komunikacji.
- Nie ma pomiaru czasu 5–9 minut dla ludzi. To historyczne założenie projektu,
  nie wynik aktualnych krótkich nagrań.
- Eksport Linux z M11 poprzedza przebudowę map. Nie jest dowodem obecnego układu;
  tę wersję uruchamia się z aktualnego projektu. Windows, dwie fizyczne maszyny
  oraz pełny benchmark wydajności obecnych map nie zostały tym raportem sprawdzone.

## 13. Zagadnienia do niezależnej oceny przez drugie AI

Poniższe pytania są przedmiotem oceny, nie opisem nowych funkcji:

1. Czy pojedyncza konstrukcja wnęki, powtórzona9 razy, daje wystarczającą odmianę
   przestrzenną i postęp nauki po poznaniu pierwszego rozwiązania?
2. Czy geometria `[P,S,P]` ogranicza wymaganą współpracę do wspólnego przemieszczania
   się i jednego kliknięcia? Co realnie zostaje z wyboru obu pozycji?
3. Czy trzy gniazda są alternatywami do rozważenia, czy głównie oczywistymi
   przypisaniami jedno gniazdo–jedna wnęka wynikającymi z bliskości?
4. Czy hazardy, które automat całkowicie omija, naciskają na moment ustawiania wiązki,
   czy są tylko łatwymi do obejścia przeszkodami w otwartym terenie?
5. Czy gracz bez instrukcji rozumie warunek48 po łamanej, zwłaszcza kiedy dron
   stojący na celu nie zasila go prostym przewodem, ale zasila po powrotnym ramieniu?
6. Czy szerokość wnęki i małe urządzenia są czytelne przy rzeczywistym skalowaniu
   okna oraz interpolacji LAN? Screeny720p nie zastępują tej obserwacji.
7. Jak sprawdzić powyższe z duetami bez prowadzenia ich po znanej trasie autora?

Raport nie proponuje ani nie wprowadza poprawek. Opisane kontrprzykłady są częścią
oceny bieżącej implementacji, nawet jeśli ograniczają wcześniejsze deklaracje o współpracy.

## 14. Źródła i identyfikacja stanu

Pierwotnym materiałem były aktualne pliki poniżej. Dokumenty projektu służyły
jedynie do identyfikacji historycznych wyników i otwartych bramek, nie do
zastępowania odczytu reguł. Ścieżki są względne wobec katalogu projektu.

| Plik / funkcja | Podstawa opisu |
|---|---|
| data/gameplay.json; core/game_config.gd::validate | parametry i ich walidacja; część liczb także literalnie w systemach |
| data/maps/dock.json, garden.json, reactor.json | wszystkie pozycje, ściany, hazardy i tła |
| core/map_definition.gd::from_json/validate/_reachable | schema, sortowanie ID, obszary bezpieczeństwa, flood-fill |
| core/world_state.gd::reset; core/simulation.gd::initialize/reset_sector | stan początkowy, warianty i przenoszenie stanu |
| core/simulation.gd::step/_consume_actions/_resolve_phase/_advance_timers | kolejność zdarzeń, sockety, ekstrakcja, czas i timery |
| core/movement.gd::begin_dash/step; core/collision_world.gd | ruch, zryw, ściany i brak kolizji dron–dron |
| core/link_system.gd::find_socket/evaluate/hits_beacon | długość, zasłonięcie, gniazda i dokładna reguła trafienia |
| core/objective_system.gd::step/finish_sector/final_score | ładowanie, zanikanie i wynik |
| core/hazard_system.gd::phase_at/hits/apply | fazy, swept damage, odporność i wspólne zdrowie |
| project.godot; app/input_router.gd | bindingi, deadzone, seriale, brak zastosowania settings.bindings |
| app/app_root.gd::_unhandled_key_input/_input_enabled/_physics_process/_render_network | tryby wejścia, F2, Escape, HUD i różnice LAN/lokalnie |
| ui/menu_presenter.gd; ui/lobby_presenter.gd; net/lobby_state.gd | rzeczywiste formularze, ready, seed/trudność i przyciski |
| app/match_session.gd; net/host_replication.gd | countdown, głosy, ticki, wejścia, timeouty i autorytet hosta |
| net/client_prediction.gd; net/network_clock.gd; net/snapshot_buffer.gd | predykcja, zegar i widok partnera |
| presentation/world_view.gd; presentation/link_view.gd | oznaczenia, hazardy, ringi, ping i prezentacja przewodu |
| tools/map_solution_hints.json; tools/record_success_fixtures.gd; tests/fixture_replay.gd | autor znanej trasy i format rzeczywistych komend |
| tests/unit/test_relay_puzzles.gd; tools/check_relay_geometry.gd | zakres dowodu działania przekaźników |
| tests/unit/test_simulation.gd, test_link.gd, test_hazards.gd; tests/integration/test_flow.gd | zakres sprawdzeń i użycie specjalnych fixture |
| tests/fixtures/{dock,garden,reactor}_success.json | dokładne wejścia oraz końcowe czasy, integrity i wyniki |
| docs/reports/map-redesign/{all-final.log,geometry.log,content-final.log,render.log,summary.json} | wcześniej wykonane sprawdzenia aktualnej przebudowy |
| tests/manual/playtest_matrix.md | odnotowany brak playtestów nowych duetów |

### Identyfikacja kodu i danych

Godot zadeklarowany w manifeście: `4.5.2`, engine build `6ce3de25aa58466e14ef354703ba8d9791a417da`.
Build label `M11ab-dev`, code_revision `unversioned` (brak wersjonowania Git).

Content SHA-256: `0039c9be838c29b25db3a6e014b368759cfd5e141595a91b4480637fabf72871`.

Podczas analizy niezależnie przeliczono hash zgodnie z `tools/build_manifest.gd`: posortowane pliki z data/core/net/app, długości i nazwy ścieżek oraz bajty zawartości. Wynik zgadza się z manifestem i raportem poprzednich testów. Ten hash **nie obejmuje** m.in. presentation, ui, tools i tests; nie jest pełnym hashem całego projektu. Poniższe hashe dodatkowo identyfikują wybrane pliki istotne dla wniosków.

| Plik | SHA-256 |
|---|---|
| data/gameplay.json | `fe53ab99b54d6410a71fa1e1f5eb8774a0fc831f38802287e50eeab47261b575` |
| data/maps/dock.json | `9cb8b3e944336b749830976b56c66e969e26e7cb57fae6e794cdc67ae387ba16` |
| data/maps/garden.json | `0c936c59f92b34540340baa52a95d06ad146ab2b9f2a3924a182beb1e7a7e420` |
| data/maps/reactor.json | `3b75c721068baad34e34b426a55445f5a0980d4f9be8d1a7366c7de5d301be3c` |
| core/link_system.gd | `0439e87f147d989caf95c0b6c9540b1bde655d2f6c2bf8bb05d1e155ac7e567c` |
| core/simulation.gd | `4ddf3719cf219b50426413bdc60ac654c05bc83a8c4aca871a26a6073778fcbb` |
| core/hazard_system.gd | `0a0170e3e472b0b582ed77a9416c88ed905433306b3c30c9d8812b8d1d0b303d` |
| core/collision_world.gd | `a0e59cf975ae3ca485d5e1f9a3b11da61cdefcc27fb7b41181a45f09065f7eb5` |
| app/input_router.gd | `362b03158a78fd1eb180d1a942cd2c17c90f766107451e96a9bebec5d0a3cde8` |
| presentation/world_view.gd | `d5c2f561c57e4d0afe34cfde3c6b9e82ad240a6b96c9a6a86e71cc49770932b7` |
| tools/map_solution_hints.json | `f156af1c8041fea2be5c99f31712b167ee1e5a207179f912d0a963e5e79bbed8` |
| tests/unit/test_relay_puzzles.gd | `952d23916fe3eea307b38ae1bb7687e5a48216b2622abcf8bf0fbec72f0563db` |
| tools/check_relay_geometry.gd | `22a0677535ea65369df5de29e1aca76953e239e2a165157e7be0ca01d2b45da9` |
| tests/fixtures/dock_success.json | `58dd669009f11e39d4caefec73f8a608ecf8f5ca01c817487fd995ee21c6d277` |
| tests/fixtures/garden_success.json | `f821716f529c8ab89e789739155b4b47d14634fa3de223851d3e9c50e751c2ba` |
| tests/fixtures/reactor_success.json | `ccdce1954a8e15b10e51de0e8fbdb9fadf78f91b5d75713d70fd05d5ac607df6` |
| docs/reports/map-redesign/all-final.log | `44f71e85ec72f3cb98eb9b208e17b51e9ac5fc69893bc554ddbaab2354a617ec` |

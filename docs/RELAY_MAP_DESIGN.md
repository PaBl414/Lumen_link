> **HISTORYCZNE: stan sprzed M11c.** Dziewięć wnęk zastąpiono. Aktualne układy, reguły i wyniki: [M11c](M11C_POZIOMY_I_WSPOLPRACA.md).

# Mapy z przekaźnikami — 2026-11-15

Przebudowa na prośbę gracza po obserwacji, że wszystkie cele można zasilić,
prowadząc drony razem. Zmienione są trzy mapy produkcyjne, nie tylko scena F2.

## Zasada zagadki

Każdy cel leży we wnęce z jednym wejściem. Za celem jest gniazdo.
Gracz podchodzi do gniazda i wciska E; potem ustawia przewód z drugim graczem
przez wejście, cel i gniazdo. Oba ramiona muszą zmieścić się w otworze i nie
przecinać ścian. Następna wnęka ma inne położenie lub kierunek wejścia, więc
trzeba wybrać inne gniazdo oraz zmienić ustawienie dronów. Poprzedni zaczep
można odpiąć lub zastąpić następnym przez E. Cele nadal ładuje się w kolejności
numerów; po trzech celach obaj gracze utrzymują się w wyjściu przez 2 sekundy.

Nie dodano sprawdzania „wciśnięto E”, przypisanych ID urządzeń ani zakazu
ładowania bez socketu. O wyniku decydują dotychczasowe ściany, geometria
przewodu i wymagane 48 jednostek od końców. Właściwe gniazdo działa, ponieważ
powstaje droga światła. Inne gniazda w sprawdzonych ustawieniach tej drogi nie dają.
Drony nadal przenikają przez siebie; nie wymagamy konkretnej odległości między nimi.

## Trzy układy

| Sektor | Kierunki otworów celów według ID 0/1/2 | Element współpracy |
|---|---|---|
| dock | prawo / dół / lewo | poznanie powrotnej trasy światła; zmiana strony podejścia |
| garden | góra / prawo / dół | obrót ustawienia wokół rozproszonych wnęk |
| reactor | lewo / dół / góra | kolejne przejścia przez centralne korytarze i wybór nowego zaczepu |

Kolejność numerów zależy od wariantu. Zagrożenia PULSE leżą na drogach między
wnękami. Mają istniejący rytm ostrzeżenia; samo ustawienie do ładowania nie
wymaga otrzymywania obrażeń. Zastąpiono dawne SWEEP: trudność tej iteracji
ma wynikać z odczytania trasy światła. To nie jest potwierdzony wzrost trudności.

## Dlaczego prosta linia nie wystarcza

Lokalna wnęka ma długość 80 i szerokość 48. Jej tył to x=0, otwór x=80,
boki y=±24. Cel jest w (48,0), socket w (16,0). Każda mapa obraca i przesuwa
te konstrukcje. Promień trafienia celu to 25, więc dysk trafienia nie sięga
poza otwór oddalony o 32; części przy bocznych ścianach blokuje kolizja światła.

Prosty odcinek dochodzący do celu musi mieć co najmniej jeden koniec we wnęce:
nie może wejść i wyjść przez ten sam otwór, a pozostałe trzy strony są zamknięte.
Fizyczny środek drona we wnęce mieści się w x∈[12,80], y∈[-12,12].
Jego odległość od środka celu wynosi najwyżej sqrt(36²+12²)≈37,95.
Rzut celu na odcinek jest więc bliżej niż wymagane 48 od tego końca. Cel nie
ładuje się. Z zaczepem liczy się długość po dwóch ramionach, więc ograniczenie
można spełnić dzięki rzeczywistemu zagięciu przewodu.

## Dowody i granice

- `tools/check_relay_geometry.gd`: sprawdza dokładne prostokąty ścian certyfikatu;
  odtwarza ruch zwycięskiej trasy z wyzerowanymi akcjami socket — zero ładunku
  na wszystkich trzech mapach. Log: `reports/map-redesign/geometry.log`.
- `test_relay_puzzles.gd`: właściwy zaczep zasila, prosta linia z tymi samymi
  końcami nie zasila, inne zaczepy nie zasilają; parkowanie na samym gnieździe
  nie zastępuje ustawienia przewodu.
- 18 nagrań rzeczywistych InputCommand: dojście, przełączenie przekaźnika,
  przemieszczenie i ładowanie, ekstrakcja. Bez teleportów/zmian WorldState.
  Wszystkie ukończone przez narzędzie autora. Zestaw regresji sprawdza także
  6 pełnych kampanii z zachowaniem integrity i wyniku.
- `tools/map_solution_hints.json` opisuje jedną znaną trasę do tworzenia nagrań;
  gra nie korzysta z tego pliku do rozstrzygania celów.
- `tools/map_puzzle_preview.gd` tworzy 9 natywnych podglądów ustawień; pozycje
  w tych obrazach to fixture prezentacji, a dowodem przejścia są nagrania wejścia.
- Testy nowych duetów, ocena odkrywalności, trudności i tempa: NOT RUN.
  Pozostaje bramka M10 0/5 duetów. Równoległe mapy mają wspólną zasadę wnęki;
  ta iteracja nie udaje dziewięciu różnych mechanik zagadek.

Uruchom projekt od nowa i wybierz F2 lub LAN. Starszy eksport M11 zawiera stare
mapy; bieżący stan uruchamia się przez `godot --path .`. M12 nie rozpoczęto.

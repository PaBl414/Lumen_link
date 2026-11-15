# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-15. **M10: implementacja i odbiór automatyczny PASS;
odbiór z nowymi duetami PENDING (NOT RUN).** M11 nie został rozpoczęty.
Katalog bez Git, code_revision=`unversioned`. Content SHA-256:
`e62f8ce5deeab6dc077ea0c37b23a34bd20f10a6445bf913ec0820717fccdf57`.
Historia: [M09](reports/m09/status.md), decyzje: [ADR-0010](ADR.md).

## Wdrożone

Kampania ma trzy różne mapy w kolejności **dock → garden → reactor**, także przez
LAN i w lokalnym narzędziu F2. Dock zachowuje już poprawny layout; garden i reactor
odwzorowują dokładne ściany, beacony, sockety, pulse i sweep z §7.1. Nie zmieniono
czasów, prędkości, obrażeń ani układu obiektów w celu ułatwienia testów.

Wariant (seed+17×sector)%3, cykliczna kolejność celów, offset37×v i skalowanie
RELAXED pozostają zgodne z kontraktem. Wspólne integrity, score, tick i event IDs
przechodzą między sektorami. Rewanż zaczyna nowy mecz od dock. Dane map pozostają
lokalne i wiązane hashem; wire1 już obsługuje map_id0..2, więc nie zmieniono schematów.
Klient odrzuca LoadSector z map_id niezgodnym z sektorem lub błędnym wariantem.

AssetCatalog przechowuje trzy zwalidowane mapy; SceneRouter przekazuje map_id
jawnie do ładowania wspólnej sceny world.tscn. Widok i predykcja używają geometrii
aktualnego sektora. Pozostają DEVELOPER ART; finalna grafika należy do M11.

Walidator wymaga wszystkich trzech plików, sprawdza schemat, safety i flood-fill8
od obu spawnów do socketów i wyjścia. Wynik walidacji jest cache'owany według SHA
tekstu config/mapy, lecz obiekty map są tworzone od nowa przy każdym wczytaniu.
Zmiana źródeł unieważnia cache. Zapobiega to ponownemu kosztownemu flood-fill na
krytycznej ścieżce startu sieci. Regresja potwierdza brak współdzielenia mutable map.
Pomiar lokalny: cold422524µs / warm4497µs, validation-cache.log; bez gwarancji FPS.

## Rzeczywiste fixture sukcesu

Trzy pliki `tests/fixtures/{dock,garden,reactor}_success.json` zawierają po6 przebiegów,
łącznie **18 kombinacji** mapa × wariant × trudność. Format RLE zapisuje liczbę
ticków i osie obu graczy; seriale akcji są0. Narzędzie offline wyznacza bezpieczne
końce przewodu i drogi, wykonuje rzeczywiste InputCommand, Simulation i hazardy,
a dopiero potem zapisuje wynik. Nie teleportuje dronów, nie ustawia charge,
integrity, fazy ani score. Każdy przebieg obejmuje trzy cele po300 tick i ekstrakcję120.

Niezależny replay w runnerze odtwarza zapis, porównuje dokładny czas, fazę, komplet
celów, integrity i score. Dodatkowo te same wejścia składają6 pełnych kampanii
(seed0/1/2 × NORMAL/RELAXED), ze sprawdzeniem wariantów i dziewięciu beaconów.
Wszystkie18 izolowanych tras kończy się bez obrażeń: NORMAL6 / RELAXED9.
Narzędzie zna mapę i omija całe obszary hazardów; nie jest dowodem łatwości dla ludzi.
Fixture nie korzysta z socketu ani dash, nie zastępuje testu nauki tych mechanik.
Normalny AppRoot pobiera wejścia od graczy; planner/replay działa tylko w narzędziach
oraz harnessach testowych. Nie dodano bota do wydania.

## Pliki i API

Nowe: `data/maps/garden.json`, `data/maps/reactor.json`, trzy `*_success.json`,
`tests/manual/playtest_matrix.md`, `tools/record_success_fixtures.gd`,
`tests/fixture_replay.gd` i UID oraz raporty.
Zweryfikowany i znormalizowany dock.json zachowuje normatywną geometrię.
Zmiany: `tools/validate_content.gd`, `services/asset_catalog.gd`,
`app/scene_router.gd`, `app/match_session.gd`, `app/app_root.gd`,
`ui/lobby_presenter.gd`, `tests/unit/test_content.gd`, `test_simulation.gd`,
`tests/integration/test_flow.gd`, `network_harness.gd`, `tools/build_manifest.gd`,
manifest, README i docs kontraktów/protokołu/architektury/ADR/statusu.

API: Validator.load_content → maps/config/map(dock dla zgodności starszego API);
AssetCatalog.map_for_sector(index); SceneRouter.show(scene_id,map_id=&"dock").
Simulation.reset_sector zachowuje istniejący kontrakt. Host pozostaje jedyną
Simulation; M09 prediction/clock/reconciliation nie zostały zastąpione.

## Wykonane sprawdzenia

Godot4.5.2 Standard official, Linux x86_64, Compatibility, Intel HD520.
`godot` oznacza `/home/pablo/.local/bin/godot`. Dowody: [reports/m10](reports/m10/).

| Polecenie / test | Exit | Wynik |
|---|---:|---|
| `godot --headless --editor --path . --import --quit` | 0 | import.log, brak błędów skryptów |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | content.log, wszystkie3 mapy PASS |
| `godot --headless --path . --script tools/record_success_fixtures.gd` | 0 | record-fixtures.log,18 rzeczywistych sukcesów |
| `godot --headless --path . --script tools/build_manifest.gd -- --write` | 0 | manifest-write.log, M10-dev |
| `godot --headless --path . --script tools/build_manifest.gd -- --check` | 0 | manifest-check.log, Manifest PASS |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | **966 PASS,0 FAIL**,15 suites; all.log |
| runner `--suite=all --self-test-failure` | 1 |965 PASS +1 celowo błędne sprawdzenie; self-test.log, wykonane przed dodaniem regresji cache |
| dwa osobne procesy ENet, `network_harness.tscn -- --scenario=expedition` | 0/0 | trzy różne sektory, wspólny wynik; process.commands.json i expedition-{host,client}.json |
| natywne GUI — trzy mapy, realne InputCommand | 0 | gui-maps.commands.json, gui-{dock,garden,reactor}.png |
| dwa natywne okna AppRoot/LAN, cap60FPS | 0/0 | sterowanie obu slotów, Escape, resume, opuszczenie; gui.commands.json, PNG i logi |

Przebieg ENet używa seed0/RELAXED i zapisanych komend wejścia. Harness po końcu
nagrania może skorygować podejście do wyjścia przez InputCommand, gdy sieć pominęła
część wejścia; dokładny replay offline pozostaje bez korekt. Obie strony mają
3 Begin i9 beaconów, wynik20590, integrity9 i wspólny tick końca6525. Gość nie ma
Simulation. Szczegółowe ID, tick i hash zawierają JSON-y; ich zgodność została
porównana. Nie używano mutacji świata w tym przebiegu.

C02 obejmuje18 konfiguracji schematu/safety/reachability oraz18 niezależnych
replay sukcesu; nie opiera się wyłącznie na flood-fill. Zostają regresje M09 PR01–03,
N03 oraz M08 N06/S01 i10 rewanżów. Test F01 przechodzi rzeczywistą sekwencję trzech
map przez AppRoot/SceneRouter i zapisuje rekord raz. Nie powtarzano oddzielnego
procesowego SIGKILL/loss z M09 — raport historyczny pozostaje w reports/m09.

GUI podglądu map używa WorldView/Simulation i wejść fixture; dodatkowy smoke dwóch
okien używa normalnego AppRoot, automatyzacji intencji lobby i klawiatury X11.
Obejrzano wszystkie trzy mapy. Pomocniki GUI i ich źródła zachowano jako `.txt`.
To odbiór layoutów z developer art, bez oceny finalnej grafiki lub pomiaru FPS.

`Couldn't create an ENet host` w all.log i self-test.log jest oczekiwanym wynikiem
negatywnego testu zajętego portu. Finalne logi nie mają SCRIPT ERROR/crashy/wycieków.
„Partner opuścił grę” na końcu GUI jest oczekiwanym teardown hosta.

## Pozostała bramka jakości — PENDING

[Macierz playtestów](../tests/manual/playtest_matrix.md) zawiera18 wierszy,
numery seedów, czasy replay i status manualny. **Manualnie0/18, nowe duety0/5:
NOT RUN**. Brak dostępnych uczestników; automatu nie przedstawiono jako playtestu.
Wymaganie co najmniej4/5 nowych duetów z pierwszym celem w90s nie jest odebrane.
Nie zmieniano balansu bez obserwacji; ewentualne korekty wymagają ADR, ponownego
replay, walidacji i manifestu. M10 nie ma jeszcze pełnego odbioru z ludźmi.

Windows↔Linux i dwa fizyczne komputery LAN/Wi-Fi nadal NOT RUN jako osobna bramka
wydania. Licencja projektu wymaga decyzji. M11 (finalny art) nie został rozpoczęty;
wdrożenie kodu M10 nie oznacza ukończenia całej gry.

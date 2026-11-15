# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-14. Kontrakt 1.0. Bieżący etap: **M01 — dane mapy i geometria kolizji**.
Kod ukończony; odbiór M01: PASS. M00 zachowany (raport: reports/m00/status.md).
Bieżący commit: brak, katalog bez repozytorium Git. Następny etap: M02, nierozpoczęty.

## Zakres

Utworzono: core/game_types.gd, core/game_config.gd, core/map_definition.gd,
core/collision_world.gd, data/gameplay.json, data/maps/dock.json,
tools/validate_content.gd, tests/unit/test_content.gd, tests/unit/test_collision.gd,
tests/fixtures/valid_map.json, tests/fixtures/invalid_map.json oraz raporty reports/m01/.

Zmieniono: app/app_root.gd, app/app_state.gd (domknięcie ADR-0001), tests/test_runner.gd,
README.md, docs/ADR.md i niniejszy status. Godot wygenerował identyfikatory .gd.uid.
Specyfikacja bazowa i dokumenty normatywne bez zmian kontraktu.

Działające API: GameTypes (enumy/DTO/Result), GameConfig.from_json/validate,
MapDefinition.from_json/validate, CollisionWorld.configure/move/blocks_segment,
walidator CLI. AppState.Result jest aliasem GameTypes.Result.

Dock zawiera dokładne normatywne pozycje ścian, beaconów, socketów, spawnów,
wyjścia i trzech hazardów. Walidacja odrzuca błędne schematy/typy/ID, nieznane klucze,
NaN, niepoprawne timery/tickrate, przekroczenie limitów, nakładające się ściany,
niebezpieczne strefy i niedostępne cele dojścia (flood-fill co 8 units dla obu spawnów).
CLI sprawdza limit 64 KiB i wymaga tylko dock. Background_asset jest obowiązkowym
identyfikatorem; nie jest jeszcze odwołaniem do dostarczonej grafiki.

Kolizje: swept AABB, powiększenie ścian o 12, cztery granice tym samym algorytmem,
slab, X przed Y i kolejność ID (mapa sortuje dane po ID), margines 0,01,
limit trzech iteracji slide, zachowanie faktycznych odcinków toru.
Drobne przeniknięcie <0,02 korygowane najmniejszą osią; większe wymaga autorytetu.
Test widoczności używa tego samego slab z podanym paddingiem; kontakt blokuje.

Menu nadal działa. Przycisk lub F1 przełącza diagnostyczny podgląd dock z tych samych
danych. Ponowne naciśnięcie wraca do menu. Nie ma ruchu dronów ani sesji/sieci.

## Weryfikacja

Godot 4.5.2 Standard, build 6ce3de25a, /home/pablo/.local/bin/godot.
Linux, rzeczywiste GUI OpenGL Compatibility na Intel HD 520, X11/XWayland.
W poleceniach poniżej `godot` oznacza ten executable. Logi: [reports/m01](reports/m01/).

| Polecenie/sprawdzenie | Exit | Wynik i dowód |
|---|---:|---|
| `godot --headless --editor --path . --import` | 0 | PASS, import.log |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | PASS: 97 asercji, 0 failed, all.log |
| Ten sam runner z `--self-test-failure` | 1 | PASS detekcji celowego błędu, self-failure.log |
| `godot --headless --path . --script tools/validate_content.gd` | 0 | PASS dock; garden/reactor pending, validator.log |
| Walidator w zaimportowanej kopii projektu z invalid_map jako dock | 1 | PASS odrzucenia spawnu w ścianie, invalid-validator.log |
| `godot --path . --display-driver x11` | 0 | PASS: menu, przełączenie podglądu i powrót, Zamknij; gui.log/gui-final.log, menu.png/dock.png |

C01: dokładny dock, błędny tickrate/NaN, brakujące pola, obce klucze, 33 ściany,
9 hazardów, overlap spawn/ścian/socketów, nieosiągalne sockety/wyjście,
strefy bezpieczeństwa wyjścia i spawn. K01: dash w ścianę, slide, tor, cztery granice,
kontakt/parallel LOS, korekcja małego przeniknięcia. K02: remis w narożniku
niezależnie od kolejności ścian. B01: trzy cykle menu/cleanup i wcześniejsze testy M00.

## Ograniczenia

Garden/reactor pending do M10; finalne assety do M11. Flood-fill potwierdza dojście,
nie rozwiązywalność zagadki przewodu. Gra nadal nie ma gameplayu — to następne etapy.
GameConfig wymaga dokładnego startowego balansu 1.0; przyszłe przyjęte zmiany balansu
muszą aktualizować również wzorzec walidacji (ADR-0002).
DTO RenderFrame używa RefCounted dla przyszłych PlayerState do ich dostarczenia.
Testy Windows, fizycznego pada, LAN i pełnej rozgrywki: NOT RUN, poza odbiorem M01.
Nie wdrożono M02. Zewnętrznie nic nie opublikowano.

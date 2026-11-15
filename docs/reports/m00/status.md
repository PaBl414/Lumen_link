# PROJECT_STATUS — LUMEN LINK

Data: 2026-11-14. Kontrakt bazowy: 1.0, protokół docelowy: 1.
Etap: **M00 — Uruchamialny fundament**. Kod: ukończony. Odbiór M00: **PASS**.
Ostatni odebrany milestone: M00. Następny: M01 (nie rozpoczęty).
Bieżący commit: brak — przekazany katalog nie jest repozytorium Git; nie tworzono commita.
Nie jest to ukończona gra ani kandydat do wydania.

## Rzeczywiście istniejące moduły i API

- `AppRoot`: `_ready()`, `shutdown()`, obsługa zamknięcia okna, jeden composition root,
  wyłączony automatyczny multiplayer poll, start w Boot i przejście do Menu.
  `shutdown()` ma flagę idempotencji; nie odwołuje się do przyszłych usług.
- `AppState`: Screen BOOT/MENU, `current`, `return_to`, `allows(next)`, `transition(next)`.
  Działający lokalny Result; docelowe GameTypes.Result dołączy z M01 (ADR-0001).
- `scenes/app.tscn`: realne menu, przycisk „Zamknij”, focus klawiatury, polskie teksty.
- `TestAssert`: equal/near/is_true/fails/summary, jawne liczniki i przypadki.
- `TestRunner`: jawny dispatcher unit/integration/all, JSON, obsługa błędnego argumentu,
  niedziałającego wymaganego skryptu i flagi `--self-test-failure`.
- `test_boot`: rzeczywista instancja sceny, trzy cykle boot/cleanup, tabela stanów,
  listener/focus przycisku, parametry projektu, wejścia i kontrola helperów asercji.

Runtime nie zawiera core, symulacji, sesji, usług zapisu, sieci, widoku świata ani audio.
Nie ma referencji runtime do tych nieistniejących modułów. Nie otwiera portów.
Viewport 1280×720, `canvas_items`/`keep`, start 1280×720, minimum 960×540,
Compatibility, fixed tick 60 Hz. Wejścia klawiatury/pada z deadzone 0,20 są skonfigurowane;
logika gameplayu używająca tych wejść nie należy do M00.

## Pliki

Utworzono wszystkie pliki wymagane przez Prompt M00:

- `project.godot`, `.gitignore`, `.editorconfig`, `README.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md`.
- `docs/MASTER_SPEC.md`, `GAME_DESIGN.md`, `ARCHITECTURE.md`, `NETWORK_PROTOCOL.md`,
  `CODE_CONTRACTS.md`, `IMPLEMENTATION_PLAN.md`, `PROJECT_STATUS.md`, `ASSET_MANIFEST.md`,
  `TEST_PLAN.md`, `RELEASE_CHECKLIST.md`, `ADR.md` (wszystkie w `docs/`).
- `app/app_root.gd`, `app/app_state.gd`, `scenes/app.tscn`.
- `tests/test_runner.gd`, `tests/test_assert.gd`, `tests/integration/test_boot.gd`.

Dodatkowo: pięć identyfikatorów `.gd.uid` generowanych przez Godot oraz raporty
w `docs/reports/m00/`. MASTER_SPEC jest identyczną bajtowo kopią pliku źródłowego.
Dokumenty tematyczne zawierają dokładne rozdziały według §27.1, bez skracania tabel
ani kontraktów. Źródłowy `LUMEN_LINK_Plan_Produkcji.md` pozostawiono bez zmian.
Nie było wcześniejszych plików implementacji do zmiany.

## Weryfikacja

Narzędzia: Godot `4.5.2.stable.official.6ce3de25a` Standard z oficjalnego godot-builds,
Bash, Python 3 do rejestracji wyników. Silnik zainstalowany poza repozytorium:
`/home/pablo/.local/bin/godot`. GUI: OpenGL 4.6 Compatibility,
Mesa Intel HD Graphics 520; Linux, KDE/Wayland z oknem X11/XWayland.
Pełny opis środowiska i hashe: [environment.json](reports/m00/environment.json).

Poniższe `godot` oznacza wyżej wymieniony pełny plik executable.

| Sprawdzenie / rzeczywiste polecenie | Exit | Wynik | Dowód |
|---|---:|---|---|
| `godot --headless --editor --path . --import` (usunięty cache `.godot`) | 0 | PASS — czysty import/parse | `final-import.log`, `final.commands.json` |
| `godot --headless --path . --script tests/test_runner.gd -- --suite=all` | 0 | PASS — 54 asercje, 0 błędów | `final-all.log` |
| Ten sam runner z `--suite=integration` | 0 | PASS — 54 asercje, 0 błędów | `integration.log`, `tests.commands.json` |
| Ten sam runner z `--suite=unit` | 0 | EMPTY — 0 suites; brak unit w M00 | `unit.log` |
| Ten sam runner z `--suite=all --self-test-failure` | 1 | PASS kontroli runnera — dokładnie 1 celowy FAIL | `final-self-test.log` |
| Ten sam runner z `--suite=missing` | 1 | PASS odrzucenia nieznanej suite | `unknown-suite.log` |
| Runner integration w tymczasowej kopii z błędem parsowania wymaganego test_boot | 1 | PASS wykrycia uszkodzonego skryptu | `broken-suite.log`, `final.commands.json` |
| `godot --path . --display-driver x11` — oględziny i kliknięcie Zamknij | 0 | PASS — rzeczywiste GUI i zamknięcie procesu | `gui-final.log`, `menu.png`, `environment.json` |
| Porównanie bajtów źródła z MASTER_SPEC | 0 | PASS | `environment.json` |

Ścieżki dowodów odnoszą się do [reports/m00/](reports/m00/).
Screenshot przedstawia końcową konfigurację `keep`; teksty, przycisk i letterboxing
zostały obejrzane. Kafelkujący compositor wymusił fizyczne okno 938×998 mimo preferencji
1280×720/minimum 960×540, co pozwoliło sprawdzić zachowanie przy nietypowej proporcji.

## Ograniczenia i dalsze prace

Brak znanych blockerów odbioru M00. B01 obejmuje dostępną scenę/menu;
walidacja brakujących assetów sektorów będzie możliwa po wdrożeniu katalogu zasobów.
Windows, dwa komputery/LAN, pad fizyczny, wydajność i testy całej gry: **NOT RUN**;
nie są kryterium odbioru fundamentu M00. Kryteria wydania pozostają NOT RUN.
Export templates nie były potrzebne do M00 i nie zostały zainstalowane.

M01: dane mapy i geometria kolizji, w tym docelowe GameTypes.Result.
Zatrzymano pracę po M00 zgodnie ze zleceniem.

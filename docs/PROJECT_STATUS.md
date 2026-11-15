# PROJECT_STATUS — LUMEN LINK

**Rozszerzenie do9 poziomów ukończone.** M00–M11c pozostają wykonane. M12a jest częściowo wykonany: katalog, wybór/podgląd poziomów, trudność, odblokowania, kontynuacja, rekordy i trwały zapis. Pełne menu/ustawienia M12, audio M13 i wydanie/odbiór M14–M15 nadal wymagają dalszej pracy.

## Zmiany i poziomy

Jeden uporządkowany katalog stabilnych ID: `data/levels.json`. Przepływ/UI/sieć/zapis nie zakładają trzech map; limit64 to limit formatu. Dock, Garden i Reactor zachowują identyczne dane względem końcowego generatora M11c (original-maps.json). Sześć nowych map ma po trzy cele i wspólną ewakuację:

| Poziom | Zadanie obu graczy |
|---|---|
|4. Rozdzielnia|Wybór między dłuższą bezpieczną trasą a krótszym ramieniem/przejściem przy PULSE, potem inny narożnik i odłączenie zaczepu.|
|5. Kanały serwisowe|Osobne drogi nad/pod długą przegrodą, inne zagrożenia po obu stronach i synchronizacja przy zaczepach.|
|6. Obserwatorium|Bezpieczna nauka przesłony, wybór otwartego ramienia między dwoma zaczepami i dwa etapy orbity.|
|7. Komora zakłóceń|Opuszczanie JAM kolejno przez różnych graczy, powrót do stanowisk i odbudowa wiązki.|
|8. Rdzeń pomocniczy|Trzy dwufazowe zadania, przełączanie zaczepów i wybór krótkiego ryzykownego albo zewnętrznego dojścia.|
|9. Serce stacji|Trzy dwufazowe obwody, zmiany obu końców i operatora zaczepu, PULSE/SWEEP/SHUTTER/JAM, potem ewakuacja. Dolna część lewego pola pierwszego celu daje czytelne schronienie przed SWEEP.|

Przesłona optyczna w aktywnej fazie blokuje oba odcinki przewodu, przepuszcza drony i nie rani. JAM wyłącza całą parę po kontakcie collidera dowolnego drona; odporność/zryw nie anulują zakłócenia. Oba typy mają dane cykli i faz hosta, obrys, zapowiedź i komunikat. Pełny snapshot protokołu3 zawiera stabilne ID, zatrzaski150 i maski przeszkód. Znacznik blokady wypada na rzeczywistym zablokowanym odcinku.

Ruch240, zryw720/10 ticków/cooldown90, wspólne zdrowie, limit przewodu720, geometria kolizji i ładowanie300 pozostają zachowane. Każdy poziom zaczyna się od integralności6/9, czasu i wyniku0; punkty i zdrowie nie przechodzą między mapami. Dalej/powtórka/wybór wymagają dwóch zgodnych głosów.

## Wybór i zapis

Ekran wyboru pokazuje numer/nazwę, rzeczywisty podgląd, blokadę/ukończenie i rekordy Normal/Relaxed. Ten sam selektor działa w menu i lobby hosta. Host zmienia mapę/trudność/seed, zerując obie gotowości. Gość widzi wybór przed gotowością i może wejść do mapy odblokowanej przez hosta.

`user://progress.json`, schema1: ukończenia po ID, rekordy według trudności i ostatni wybór. Odblokowania wyliczane z katalogu; pierwsza mapa dostępna od razu, ukończenie otwiera następnik. Kontynuuj wybiera pierwszy nieukończony; po całej kampanii zostaje wybór z informacją o ukończeniu. Zapis po każdym zaakceptowanym zwycięstwie, atomowe zastąpienie, `.bak` poprzedniej poprawnej generacji, odzyskiwanie, walidacja, ochrona nowszego schematu, reset z potwierdzeniem i komunikat IO z zachowaniem postępu w pamięci.

Gość zapisuje dopiero reliable wynik hosta; sam snapshot WON, porażka ani rozłączenie przed potwierdzeniem nie zaliczają mapy. Stare records.json/debug_records.json są zachowaną historią kampanii i nie stanowią dowodu ukończenia poziomów. M12 musi rozwijać LevelSelectPresenter i ProgressStore, bez drugiego ekranu lub konkurencyjnego magazynu.

## Faktycznie wykonana weryfikacja

| Zakres | Wynik / dowód |
|---|---|
| Pełna regresja końcowych map | **1813PASS /0FAIL /0SKIP**,23 zestawy,778542ms — reports/levels9/all-final.log |
| Ukończalność bez teleportów |54 konfiguracje(9×2 trudności×3 fazy),6 pełnych kampanii i przejście aplikacji; rzeczywiste InputCommand/RLE. Aktualne nagrania w tests/fixtures; ostatnie6 finału w heart-recordings-final.log.|
| Spóźnione wejścia po wyniku |Regresja przed poprawką wykazała rozłączenie; po poprawce **4PASS**. Host nadal sprawdza tożsamość/sekwencję/limity, ale nie symuluje wejść po końcu.|
| Świeże testy protokołu/LAN po poprawce |**145PASS /0FAIL** — network-final.log; wybór/ready, gość z lokalną blokadą, reliable potwierdzenie, odzyskanie zatrzasku i reset.|
| Końcowe testy runtime/UI/finału |**207PASS /0FAIL** — final-focused.log |
| Pełne LAN Normal |9/9,WON,exit0/0,identyczne wyniki obu ról; finał7190pkt,integralność6 — lan-normal/ |
| Pełne LAN Relaxed |9/9,WON,exit0/0,identyczne wyniki obu ról; finał9750pkt,integralność9 — lan-relaxed/ |
| Pliki po zamknięciu procesów |4 pliki testowe mają9 ukończeń i rekordy zgodne z wynikami; disk-*.json |
| Restart/recovery/reset |4 scenariusze w osobnych procesach i rzeczywistej AppRoot, historyczny plik bez zmian — progress-restart.json |
| Kolejność katalogu |Test odwróconego katalogu zachowuje rekordy/ukończenia po ID; wire ładuje ID z nowym ordinalem.|
| Prezentacja |12 natywnych zrzutów1280×720: selektor świeży/ukończony,9 map i schronienie finału. Sprawdzono nowe mapy i selektor. To kontrola techniczna, nie playtest.|
| Eksporty |Import, Linux x86_64, Windows x86_64 debug, Linux boot oraz ENet host/gość: wszystkie exit0 — export.commands.json |
| Manifest |PASS — manifest-check.log |

Pełna regresja23 zestawów obejmuje końcową geometrię; po jej starcie dodano poprawkę spóźnionych wejść. Tę zmianę sprawdzono oddzielną regresją4 przypadków,145 testami i pełną kampanią Relaxed. Kampania Normal przeszła na tych samych końcowych mapach przed samą poprawką guardu. Nie sumujemy zachodzących na siebie zestawów jako nowych niezależnych testów. Błąd zajętego portu w pełnej regresji jest oczekiwanym testem negatywnym; brak SCRIPT ERROR/Parse Error. Historyczne nieudane próby i przerwane przebiegi są w attempts/; summary.json zawiera wyłącznie wskazane końcowe dowody.

## Pozostaje dla ludzi

Playtest frajdy, intuicyjności i odczuwalnej trudności: **NOT RUN**. LAN testowano dwoma procesami Linux/loopback, nie dwoma fizycznymi komputerami. Runtime Windows: NOT RUN (wykonano eksport). Pełny benchmark60FPS i odbiór wydania: NOT RUN. Nagrania dowodzą istnienia rozwiązań, nie braku każdego możliwego skrótu w przestrzeni ciągłej. Fixtures techniczne przygotowujące wynik/latch nie są przedstawiane jako przejście mapy.

## Uruchomienie i materiały

Godot4.5.2 Standard → Wybierz poziom / LAN → Kontynuuj albo Zagraj wybrany poziom → pokój/gotowość/start. WASD/Spacja/E/Q; lokalny test F2: drugi gracz IJKL/Shift/U/O. Escape pokazuje menu bez pauzowania hosta.

Eksporty developerskie poza repo: `~/.local/share/lumen-tools/levels9-smoke/linux/` i `windows/` (oddzielne PCK). Nie są wydaniem dystrybucyjnym. [Poziomy/rozwiązania](LEVELS9.md) · [Zapis i wybór](PROGRESS.md) · [Odbiór ręczny](LEVELS9_MANUAL.md) · [Protokół](NETWORK_PROTOCOL.md) · [Wyniki](reports/levels9/summary.json).

Build `Levels9-dev`, protocol3, schema zapisu1, code_revision=unversioned.
Content SHA-256: `dc1b8d09a535a75591f150d111d253decf6779d537d2dc604842af2830d7896a`.
Historia M11c: reports/m11c/PROJECT_STATUS_FINAL.md.

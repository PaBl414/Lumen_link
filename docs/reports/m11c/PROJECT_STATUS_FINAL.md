# PROJECT_STATUS — LUMEN LINK

**M11c ukończony: implementacja i automatyczny odbiór aktualnej geometrii.**
M00–M11b pozostają wykonane. M12 nie rozpoczęto. Ludzka ocena rozgrywki pozostaje otwarta.

## Dostarczone zmiany

- Pola stabilizacji44: oddzielne drony w NORMAL, role zamienne, cele bez pól/z jedną parą/z dwiema parami.
- Trwały zatrzask150 i podłoga zaniku, reset sektora, maska w każdym pełnym snapshotcie protokołu2.
- Stała kolejność0→1→2; seed zmienia tylko sprawdzone fazy hazardów.
- Dock: bezpieczna prosta wiązka → narożnik i kanał światła → pola/PULSE.
- Garden: dwa etapy → zaczep/SWEEP → zmiana zaczepu i obu stanowisk z wyborem drogi.
- Reactor: rozdzielenie przy przeszkodzie → naprzemienne pulsy/dwa etapy → finał PULSE/SWEEP i ewakuacja.
- Podgląd następnej pary, osobne stany pól, etap/animacja150, wspólne komunikaty LAN/lokalnie,
  znacznik rzeczywistego kontaktu przewodu ze ścianą.
- Poprawki brzegów pól odcinające wykryte wcześniej skróty w Garden/Reactor.

Ruch, zryw/cooldown, zdrowie, ładowanie300, limit przewodu720 i kolizje zachowane.
Nie dodano globalnego zakazu nakładania dronów ani minimum kąta. Sekwencyjny import
assetów omija zaobserwowaną wcześniej awarię wątku importera fontów Godota4.5.2.

## Końcowe sprawdzenia aktualnego stanu

| Zakres | Wynik i dowód |
|---|---|
| Pełna regresja | **1146PASS /0FAIL /0SKIP**,19 suites,exit0,272868ms — reports/m11c/all-final.log |
| Przejścia bez teleportów |18 sektorów i6 pełnych kampanii rzeczywistymi InputCommand, w powyższej regresji |
| Utrata snapshotów |host zatrzaskuje150 podczas330ms przerwy; klient odzyskuje etap z kolejnego snapshotu; reset obu stron na następnym sektorze |
| Brzegi pól |24 przypadki,3,382,821 par końców,siatka4; brak znalezionego obejścia — field-routes.json |
| Cykle ładowania |78/78PASS — charge-windows.json; model stanowisk, nie pełna droga ani ludzie |
| Pełne LAN Normal |host/gość exit0/0,WON,wynik13940,integrity4,maski0/5/6 — lan-normal/lan-expedition.json |
| Pełne LAN Relaxed |host/gość exit0/0,WON,wynik19410,integrity9,maski0/5/6 — lan-relaxed/lan-expedition.json |
| Widok |13 etapów w720p+13gray,2 dodatkowe widoki(puste pole/blokada); render.log exit0 |
| Eksporty |świeży import,Linux x86_64 iWindows x86_64 debug:exit0; export.commands.json |
| Linux po eksporcie |boot z fontem i tytułem,ENet host/gość,natywny OpenGL/F2:exit0 |
| Manifest |PASS — manifest-check.log; kod i dane pozostały niezmienione podczas końcowego odbioru |

Skan siatki nie jest dowodem dla całej przestrzeni ciągłej. Techniczne fixtures
badające reset lub granice mogą przygotowywać WorldState — nie przedstawiamy ich
jako przejścia kampanii. Nagrania ukończenia i pełne LAN kierują wyłącznie wejściem.
W all-final.log błąd ENet zajętego portu jest oczekiwanym testem negatywnym;
nie ma SCRIPT ERROR/Parse Error. Końcowe import/export/render logi są bez błędów.

## Zakres pozostający dla ludzi i dalszych etapów

Nowe duety0/5:NOT RUN. Nie potwierdzono frajdy, intuicyjności, reakcji ani rosnącej
subiektywnej trudności. LAN testowano dwoma procesami na Linux/loopback,
nie dwoma fizycznymi komputerami. Windows został wyeksportowany, ale runtime
Windows nie był uruchamiany. Pełny benchmark i odbiór wydania M15 pozostają otwarte;
natywny smoke nie jest gwarancją60 FPS. M12 i audio M13 nie rozpoczęto.

## Uruchomienie i materiały

Uruchom projekt przez Godot4.5.2 Standard i wybierz F2 lub LAN.
Aktualne eksporty developerskie są poza repo w ~/.local/share/lumen-tools/m11c-smoke/
(linux/ iwindows/, oddzielne PCK). Stary katalog m11-smoke ma poprzednią zawartość.
To eksporty debug do sprawdzenia, nie wydanie dystrybucyjne.

[Instrukcja ręczna](M11C_TEST_MANUALNY.md) · [Układy i rozwiązania](M11C_POZIOMY_I_WSPOLPRACA.md) ·
[Raport dla AI](RAPORT_ROZGRYWKI_LUMEN_LINK.md) · [Zebrane wyniki](reports/m11c/summary.json).

Build `M11c-dev`, protocol2, code_revision=`unversioned`.
Content SHA-256: `15836523d54c575f2db70b76b1842f2c6f021f5e882b4dbdd331ee75438200a5`.
Historia sprzed M11c: reports/map-redesign/status.md. M11C_HANDOFF.md jest historycznym
checkpointem pauzy, nie listą niedokończonych automatycznych sprawdzeń.

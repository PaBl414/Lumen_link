# RELEASE_CHECKLIST — kontrakt 1.0

Źródło: [MASTER_SPEC.md](MASTER_SPEC.md), specyfikacja 1.0 (14 listopada 2026).
Poniższe rozdziały zachowują pełną treść źródła. Opisują wymagania docelowe; stan implementacji podaje [PROJECT_STATUS.md](PROJECT_STATUS.md).

Stan wszystkich poniższych kryteriów wydania: NOT RUN — M00 nie jest kandydatem do wydania. Build/commit: brak (repo bez Git). Dowody etapu M00: [status](PROJECT_STATUS.md), reports/m00/. Ich wyniki nie zastępują odbioru wydania.

## 28. Końcowa checklista odbioru wydania

Każdy punkt ma w repo status `PASS`, `FAIL` albo `NOT RUN`, datę, build/commit i dowód. Ta specyfikacja ustala wymagania; **nie potwierdza wykonania testów nieistniejącej jeszcze gry**.

### Rozgrywka i zawartość

- [ ] W grze uczestniczy dokładnie dwóch ludzi na osobnych komputerach. Bez partnera nie można rozpocząć ekspedycji.
- [ ] Każdy z trzech sektorów ma ukończony layout, tło, urządzenia, hazardy i ewakuację.
- [ ] Wszystkie 18 kombinacji mapa × wariant × trudność przeszły sprawdzenie rozwiązywalności.
- [ ] Ruch, zryw, socket, przewód, charge, integrity i score realizują dokładne reguły z GDD.
- [ ] Cel kończony w ostatnim ticku zalicza się; integrity=0 ma pierwszeństwo przed ewakuacją.
- [ ] Całą ekspedycję można wygrać, przegrać i powtórzyć; wynik nie nalicza się dwukrotnie.
- [ ] Co najmniej 4 z 5 nowych duetów potrafią zasilić pierwszy cel w 90 s bez tłumaczenia przez prowadzącego albo udokumentowano i naprawiono przyczynę niepowodzenia przed ponownym testem.

### Sieć

- [ ] Windows host → Linux client oraz Linux host → Windows client: pełna ekspedycja bez internetu.
- [ ] Direct IP działa niezależnie od discovery. Brak broadcastu ma czytelną alternatywę.
- [ ] Hello odrzuca niezgodny protocol, engine build i content hash.
- [ ] Wszelkie wyniki, obrażenia i przełączenia celów rozstrzyga host.
- [ ] Snapshot ma 107 B, PlayerRecord35 B, nagłówek22 B; kodek przechodzi niezależne golden vectors.
- [ ] Duplikaty i utrata pakietów nie uruchamiają jednej akcji wiele razy.
- [ ] Timer, cooldowny i seriale po reconciliation są zgodne ze snapshotem hosta.
- [ ] Utrata połączenia zamyka sesję w określonym czasie i nie blokuje nowego hostowania.
- [ ] Trzeci klient nie wchodzi do meczu. Pakiety starego sektora i meczu nie zmieniają nowego.
- [ ] 30 cykli rematch/leave nie powiela signal listeners, nie zostawia portów ani scen.

### Obraz, dźwięk i UX

- [ ] W release nie ma developer art, brakujących tekstur, domyślnych debug labels ani niedziałających przycisków.
- [ ] Własny i zdalny dron są rozpoznawalne po sylwetce, nie wyłącznie po kolorze.
- [ ] Hazard zawsze uprzedza o aktywacji; animacja odpowiada rzeczywistemu czasowi symulacji.
- [ ] 960×540,1280×720,1920×1080 i ultrawide zachowują pole gry i użyteczny interfejs.
- [ ] Wszystkie ekrany obsługuje klawiatura i pad. Focus nie ginie po modalach i zmianie ekranu.
- [ ] Reduced motion, shake=0, ui_scale1,3 i remap działają, a nie tylko zapisują wartości.
- [ ] Odsłuch potwierdza brak klików, przesterowania, podwójnego dash oraz narastających loopów.
- [ ] Menu podczas meczu wyraźnie informuje, że gra nadal trwa.

### Wydajność, stabilność i paczki

- [ ] Budżety60 FPS, frame pacing, RAM i bandwidth sprawdzono na opisanym sprzęcie bazowym; raport zawiera sprzęt, OS, driver, preset i commit.
- [ ] Cel120 FPS ma oddzielny wynik i nie jest przedstawiany jako gwarancja dla każdej maszyny.
- [ ] W steady state nie ma stallów>50 ms ani obowiązkowego ładowania assetów w środku akcji.
- [ ] Wszystkie wymagane suites przeszły; brak testów oznaczonych jako PASS bez wykonania.
- [ ] Release nie zawiera debug harness, developer input ani testowego wczytywania komend z pliku.
- [ ] Obie paczki startują na czystym koncie bez zainstalowanego Godota.
- [ ] Gra zapisuje do user://, działa przy read-only katalogu instalacji i obsługuje błędny config.
- [ ] Archiwa mają właściwe uprawnienia, licencje, README, manifest i opublikowane lokalnie checksumy.
- [ ] Nie ma niezamierzonych połączeń internetowych, usług telemetrycznych ani runtime downloadów.
- [ ] MASTER_SPEC, dokumenty tematyczne, ADR, PROJECT_STATUS i rzeczywisty build opisują tę samą architekturę.
- [ ] Brak blokujących P0. Nieprzeprowadzone testy dwóch komputerów lub sprzętu bazowego pozostają jawnymi blokadami odbioru, nawet jeśli kod jest skończony.

### Źródła techniczne i granice weryfikacji

Źródła sprawdzono podczas przygotowania planu. Dokumentacja potwierdza dostępność technologii i mechanizmy silnika; liczby gameplayu, oceny koncepcji, budżety i architektura są decyzjami projektowymi. Źródła nie stanowią dowodu, że zaprojektowana gra już działa.

- **[S1]** [Godot 4.5.2-stable — oficjalne archiwum i eksporty](https://godotengine.org/download/archive/4.5.2-stable/). Potwierdzony pin wersji, Standard i .NET oraz templates.
- **[S2]** [Godot C#/.NET 4.5](https://docs.godotengine.org/en/4.5/tutorials/scripting/c_sharp/index.html) oraz [C# basics](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html). Osobny edytor .NET, SDK do kompilacji i obsługa desktop. Drugi link jest ruchomą gałęzią stable; nie jest lockfile projektu.
- **[S3]** [Static typing in GDScript 4.5](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/static_typing.html). Typy, weryfikacja i zoptymalizowane opcodes; nie jest to benchmark tej gry.
- **[S4]** [High-level multiplayer 4.5](https://docs.godotengine.org/en/4.5/tutorials/networking/high_level_multiplayer.html) i [MultiplayerPeer 4.5](https://docs.godotengine.org/en/4.5/classes/class_multiplayerpeer.html). ENet, kanały i tryby transferu.
- **[S5]** [SceneMultiplayer 4.5](https://docs.godotengine.org/en/4.5/classes/class_scenemultiplayer.html). `send_bytes`, `peer_packet`, `allow_object_decoding`, `refuse_new_connections` oraz ograniczenie kompatybilności wewnętrznego protokołu.
- **[S6]** [PacketPeerUDP 4.5](https://docs.godotengine.org/en/4.5/classes/class_packetpeerudp.html). UDP bind, broadcast i adres nadawcy.
- **[S7]** [System requirements 4.5](https://docs.godotengine.org/en/4.5/about/system_requirements.html). Compatibility i OpenGL3.3; nie gwarantuje60 FPS na wskazanym GPU.
- **[S8]** [MultiplayerAPI 4.5](https://docs.godotengine.org/en/4.5/classes/class_multiplayerapi.html) i [SceneTree 4.5](https://docs.godotengine.org/en/4.5/classes/class_scenetree.html). Ręczne poll oraz wyłączenie automatycznego poll.
- **[S9]** [Exporting for Linux 4.5](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_linux.html). Eksport projektu i zasobów do dystrybucji desktop.

**Kolejny krok wykonawczy:** przekazać ten plik do Sol i uruchomić Prompt M00. Po każdym odebranym przyroście stosować następny prompt; zachować dokumentację i raporty w tym samym repozytorium. W ramach tego zlecenia nie napisano ani nie uruchomiono gry.

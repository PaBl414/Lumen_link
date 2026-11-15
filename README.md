# LUMEN LINK

Kooperacyjna gra LAN offline dla dokładnie dwóch osób, Godot4.5.2 Standard, Windows/Linux. Obecna wersja zawiera **9 poziomów**, wybór trudności, odblokowania i trwały lokalny postęp. M00–M11c ukończone; część M12 dotycząca wyboru poziomów i zapisu została wykonana w rozszerzeniu dziewięciu poziomów.

## Uruchomienie

Otwórz `project.godot` w Godot4.5.2 i uruchom projekt (F6 uruchamia wybraną scenę, F5 projekt). W terminalu:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script tools/build_manifest.gd -- --write
godot --path .
```

Manifest aktualizuj po zmianach kodu lub danych, przed uruchomieniem obu klientów. Obie osoby muszą mieć tę samą wersję silnika i zawartość projektu. Gra nie potrzebuje Internetu ani serwera pośredniczącego.

W menu wybierz **Wybierz poziom / LAN**, mapę i trudność. **Kontynuuj kampanię** wskazuje pierwszy nieukończony poziom. Utwórz pokój albo dołącz przez IPv4 gospodarza; wyszukiwanie LAN korzysta z UDP7778, gra domyślnie z UDP7777. Host wybiera mapę/trudność/seed, obie osoby oznaczają gotowość, następnie host uruchamia rozgrywkę. Wybór można zmienić także w lobby; zeruje to obie gotowości.

WASD: ruch, Spacja: zryw, E: aktywacja/zmiana/odłączenie pobliskiego przekaźnika, Q: ping. Przeciągajcie przewód przez trzy kolejne cele. Pola stabilizacji wymagają dwóch różnych dronów w NORMAL. Po150 dwufazowego celu zmieńcie stanowiska, zachowując połowę postępu. Na końcu oba drony muszą pozostać w wyjściu przez2s. Escape neutralizuje wejście i pokazuje menu, ale nie zatrzymuje hosta.

Przesłony optyczne blokują przewód, przepuszczają drony. Strefa zakłóceń wyłącza całą parę, kiedy choć jeden dron zahacza o jej aktywny obszar; nie rani, a odporność na obrażenia jej nie anuluje. Żółty obrys zapowiada aktywację. PULSE i SWEEP wymagają odwrotu albo zrywu i ponownego ustawienia.

Każdy poziom zaczyna się z integralnością6 (Normal) albo9 (Relaxed), nowym czasem i wynikiem. Ukończenie odblokowuje następnik. Rekordy czasu i punktów są osobne dla trudności. Wynik zapisuje się na obu komputerach po autorytatywnym potwierdzeniu. Dalej, powtórka i powrót do wyboru wymagają dwóch zgodnych głosów.

Postęp: `user://progress.json`, kopia `progress.json.bak`. Uszkodzony zapis jest odzyskiwany z kopii; błąd dysku zostawia postęp w pamięci i komunikat. Reset z potwierdzeniem znajduje się na ekranie wyboru. Starsze rekordy kampanii pozostają osobną historią, bez wymyślania ukończeń konkretnych map.

Lokalny test developerski F2 uruchamia ostatnio wybrany poziom: P1 WASD/Spacja/E/Q, P2 IJKL/Shift/U/O. F1 pokazuje geometrię oryginalnego doku. Ocena LAN wymaga normalnego połączenia dwóch procesów/komputerów; F2 go nie zastępuje.

## Sprawdzenia

```sh
godot --headless --path . --script tools/validate_content.gd
godot --headless --path . --script tools/build_manifest.gd -- --check
godot --headless --path . --script tests/test_runner.gd
python3 tools/test_progress_restart.py
python3 tools/test_lan_campaigns.py
```

Pełna regresja odtwarza prawdziwe komendy ruchu dla dziewięciu map, obu trudności i trzech wariantów faz. W tym środowisku pełny przebieg trwał około13 minut. `tools/record_success_fixtures.gd` jest narzędziem autora do generowania nagrań, nie botem dostępnym graczom. Seed zmienia fazy istniejących zagrożeń, nie tworzy nowych poziomów.

Aktualne wyniki i ograniczenia: [PROJECT_STATUS](docs/PROJECT_STATUS.md). Układy, współpraca i współrzędne rozwiązań: [LEVELS9](docs/LEVELS9.md). Zapis i odblokowania: [PROGRESS](docs/PROGRESS.md). Format sieci: [NETWORK_PROTOCOL](docs/NETWORK_PROTOCOL.md). Wyniki testów nie zastępują oceny frajdy przez ludzi.

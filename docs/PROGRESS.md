# Wybór poziomu i trwały postęp

W menu wybierz **Wybierz poziom / LAN**. Katalog pokazuje numer, nazwę, podgląd rzeczywistej geometrii, blokadę/odblokowanie/ukończenie i dwa osobne zestawy rekordów. Wybierz Normal albo Relaxed, następnie **Kontynuuj kampanię** lub **Zagraj wybrany poziom** i utwórz pokój. **Dołącz do hosta LAN** pozwala wejść do wyboru gospodarza. Pierwszy poziom jest dostępny bez zapisu.

Kontynuuj wybiera pierwszy nieukończony ID według `data/levels.json`. Po ukończeniu całej kampanii pozostawia wybór map i informację o ukończeniu. Rekord punktowy jest maksimum, czasowy minimum; mogą pochodzić z różnych podejść. Odblokowania są wspólne dla obu trudności: pierwsza mapa, każda ukończona oraz następnik każdej ukończonej. Pozwala to gościowi powtórzyć ukończoną u hosta późniejszą mapę i jej następnik, bez dopisywania wcześniejszych ukończeń.

W LAN host wybiera poziom, seed i trudność. Gość widzi je w lobby przed gotowością. Zmiana któregokolwiek wyboru zwiększa revision i zeruje obie gotowości; host nie może wystartować lokalnie zablokowanego poziomu. Gość może wejść do poziomu odblokowanego przez hosta. Przycisk podglądu otwiera ten sam ekran wyboru również w istniejącym lobby, bez rozłączania partnera. Gość zatwierdza gotowość po zobaczeniu nowego wyboru.

Każda mapa kończy się osobnym wynikiem. Po zwycięstwie dwie zgodne decyzje uruchamiają następny poziom, powtórkę albo powrót do wyboru. Po porażce dostępna jest powtórka albo wybór. Głosy na różne akcje nie wystarczają; oddanie nowego głosu usuwa poprzedni głos danej osoby. Na ostatnim poziomie nie ma akcji Dalej. Po wspólnym powrocie host otrzymuje ekran wyboru z podglądem, gość pozostaje w lobby. Każdy start przywraca początkową integralność6/9, czas, wynik, cele, zatrzaski i historię wejść. Nie przenosimy zdrowia/punktów między mapami.

## Plik i odporność zapisu

Każdy komputer zapisuje lokalnie `user://progress.json` (schemat1). Typowe ścieżki domyślnego projektu:

- Linux: `~/.local/share/godot/app_userdata/LUMEN LINK/progress.json` (zależne od XDG_DATA_HOME).
- Windows: `%APPDATA%/Godot/app_userdata/LUMEN LINK/progress.json`.

Dokładna ścieżka wynika z `ProjectSettings.globalize_path("user://progress.json")`. Dane: `schema_version`, tablica `completed` stabilnych ID, `records` z `normal`/`relaxed` (`best_score`, `best_time_ticks`) i `last_selected` (`level_id`, `difficulty`). Nie utrwalamy numerów katalogu ani tablicy odblokowań. Zmiana kolejności katalogu zachowuje ukończenia i rekordy po ID; kolejność odblokowań i Kontynuuj zostaje ponownie wyliczona z katalogu. Poprawne nieznane ID są zachowane dla usuniętych/przyszłych wpisów. Nieznany ostatni wybór wraca do pierwszej pozycji.

Zapis powstaje po każdym zaakceptowanym zwycięstwie i po zmianie wyboru. Nowe dane są zapisane i flushowane do pliku tymczasowego, poprawny poprzedni główny zapis zastępuje `.bak`, a gotowy plik `.pending` zastępuje główny przez rename w tym samym katalogu. Pierwszy zapis tworzy również poprawną kopię. Uszkodzony główny plik nie zastępuje dobrej kopii; przy wczytaniu używana jest `.bak` i widoczny komunikat. Przy braku obu poprawnych wersji używamy bezpiecznych wartości domyślnych. Przerwane `.tmp`/`.pending` nie są traktowane jako potwierdzone wyniki.

Walidujemy typy, ID, duplikaty, zakresy liczb, skończoność i limit1MiB. Nowszy nieobsługiwany schemat jest chroniony przed nadpisaniem i resetem. Błąd dysku zachowuje postęp w pamięci i pokazuje komunikat w wyniku/lobby/wyborze; bez udanego zapisu nie obiecujemy zachowania go po zamknięciu procesu. Kopia jest poprzednią poprawną generacją, więc po odzyskaniu może brakować ostatniego ukończenia.

Reset wymaga potwierdzenia w osobnym dialogu. Po zatwierdzeniu resetowane są obie generacje, żeby późniejsze odzyskanie kopii nie przywróciło świadomie usuniętych ukończeń. Przy błędzie IO pozostaje komunikat; reset w pamięci nie jest gwarancją resetu na dysku.

## Autorytatywny wynik

Host zatwierdza WON dopiero po trzech pełnych celach i wspólnej ewakuacji. Pełny snapshot zawiera ID poziomu i trwałe stany. Host zapisuje wynik raz na match_id; gość robi to dopiero po zaakceptowanym **reliable SessionState(17)** z poprawnym wynikiem. Unreliable Snapshot(10) może wcześniej pokazać ekran wyniku, ale nie zalicza poziomu i nie pozwala gościowi głosować za następnym. Powtórzona reliable wiadomość nie dopisuje ponownie ukończenia. Porażka i zerwanie przed potwierdzeniem nie zapisują ukończenia; już potwierdzony zapis pozostaje po rozłączeniu.

Stare `records.json` i `debug_records.json` (schemat1 rekordów całej kampanii) pozostają niezmienione i są pokazywane jako historia osobno. Nie ma migracji tych agregatów do ukończeń poziomów: nie zawierają takiej historii. Nowe wyniki poziomów nie są dopisywane do dawnych rekordów kampanii. Reset nowych postępów nie usuwa plików historycznych.

## Zakres M12 wykonany wcześniej

Ten etap realizuje katalog, ekran wyboru/podglądów, trudność przy wyborze, odblokowania, rekordy poziomów, kontynuowanie, trwały zapis/backup/recovery/reset oraz integrację lobby/wyników. M12 powinien rozwijać te komponenty, nie tworzyć drugiego selektora albo konkurencyjnego magazynu. Pozostały zakres pełnego menu/ustawień (np. edycja powiązań i ustawienia ekranowe) nadal wymaga osobnego odbioru. Audio M13 i wydanie M14/M15 pozostają dalszymi etapami.

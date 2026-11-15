> **Checkpoint historyczny. M11c został następnie ukończony i zweryfikowany automatycznie.** Aktualne wyniki oraz otwarty zakres ludzki: [PROJECT_STATUS](PROJECT_STATUS.md). Poniższa lista dokumentuje dawną pauzę i nie jest aktualną listą zadań.

# M11c — przerwane na życzenie użytkownika

Prace WSTRZYMANE. Nie wznawiać automatycznie. M12 nie rozpoczęto.
Użytkownik poprosił o zatrzymanie uruchomionych prac i listę pozostałych kroków.

## Co już zaimplementowano

- Opcjonalne pola radius44, różni gracze/NORMAL, obie zamienne role.
- Dwufazowe pola, zatrzask150 i podłoga zaniku150; reset między sektorami.
- Map schema2, reguły celów w danych, walidacja pól i1..3 socketów; schema1 fixture nadal działa.
- WorldState/GameSnapshot.latched_mask, protokół2, snapshot108 B, gracz35 B,
  maska offset37, Snapshot/Begin130 B, SessionState135 B, limit1000.
- Walidacja snapshotów względem mapy po stronie klienta, niezależne golden vectors.
- Stała kolejność0→1→2; seed zmienia tylko sprawdzone fazy.
- Wszystkie3 mapy przebudowane, konkretne rozwiązania w tools/map_solution_hints.json.
- HUD lokalny/LAN, stany pól, podgląd przyszłej pary, animacja150, marker rzeczywistego kontaktu blokady.
- Narzędzia nagrań rzeczywistych komend, model okien ładowania, testy jednostkowe/LAN.
- Sekwencyjny import assetów w project.godot: obejście zaobserwowanego crashu
  Godota4.5.2 przy wielowątkowym imporcie fontów. Log awarii zachowano.

## Ważna ostatnia korekta — nie pomylić dowodów wcześniejszej wersji z obecną

Przegląd BRZEGÓW pól wykrył obejścia, których test samych centrów nie wykrywał.
Poprawiono geometrię/dane, nie złagodzono warunków testu:

- Garden: drugi blok [936,208,96,152], S2=(1056,512), cel2 faza2:
  P0=(776,192), P1=(944,624). Przeciwdziała zachowaniu S1 lub wcześniejszemu użyciu S2.
- Reactor: trzeci blok [784,448,48,96], cel2 faza2 P1=(1168,512).
  Przeciwdziała prostemu przewodowi i zachowaniu poprzedniego zaczepu.
- Dodano5 konkretnych dawnych obejść do test_relay_puzzles.gd.
- tools/check_field_routes.py: niezależny skan położeń w polach co4 jednostki,
  sprawdza brak zaczepu i niewłaściwe gniazda; 24 przypadki po142129 par punktów.
- Ręczna pierwsza próba skanu po korekcie: wszystkie24 bez obejścia
  (field-boundaries.log). Późniejszy automatyczny zapis JSON (field-routes.log/json)
  mógł nie dojść do końca: zatrzymany na życzenie użytkownika. Sprawdzić kompletność.

Ostatni content SHA w build_manifest.json:
15836523d54c575f2db70b76b1842f2c6f021f5e882b4dbdd331ee75438200a5
Godot4.5.2 Standard, engine6ce3de25aa58466e14ef354703ba8d9791a417da.
Źródła bez repo Git. Nie tworzyć commitów/pusha bez dalszej prośby.

## Wykonane sprawdzenia

PRZED ostatnią korektą brzegów:
- all.log:1136PASS/0FAIL,19 suites,412134ms. Zawiera18 replays i6 kampanii.
- focused-final.log:269PASS/0FAIL (uzupełnienia STUN, poprawna baza walidatora, dash).
- Pełne LAN Normal/Relaxed, score/integrity zgodne, maski0/5/6. Te wyniki w
  lan-normal-before-edge-fix i lan-relaxed-before-edge-fix.
- Linux+Windows debug eksport, Linux boot/LAN/native0; eksporty również sprzed korekty brzegów.
- Obrazy13 ustawień oraz gray, z odczytu1280x720; źródła prezentacji są już po poprawkach
  warstwy pól nad ikoną wyjścia i etykiet poza sylwetką drona.

PO ostatniej korekcie brzegów:
- content-final.log: walidator PASS.
- geometry-final.log:107PASS/0FAIL, w tym dawne obejścia.
- dash-route.log:16PASS/0FAIL, opcjonalny zryw przez aktywny PULSE w ogrodzie.
- charge-windows.log/json:78/78PASS (model stanowisk z rezerwą24+36 ticków,
  nie pełna droga ani ludzki playtest).
- Garden i Reactor ponownie nagrane (garden-record-final.log/reactor-record-final.log).
  Odczyt przy pauzie: wszystkie3 pliki fixture po6 rekordów ok=true.
  Dock nie zmieniał się przy ostatniej korekcie. Szczegóły pause-state.json.
- Najnowsze pełne kampanie LAN w lan-normal i lan-relaxed ZATRZYMANO na prośbę
  użytkownika. Nie traktować SIGTERM/braku wynikowego JSON jako porażki rozgrywki ani PASS.

## Co pozostało do ukończenia

1. Odczytać stan zapisanych logów/JSON, sprawdzić wszystkie6 nowych nagrań Garden/Reactor.
2. Dokończyć check_field_routes.py ze ścisłym exit0 i kompletnym JSON; potwierdzić brak obejść.
3. Uruchomić pełny test_runner --suite=all na OSTATECZNYCH danych (obejmuje18 sektorów,
   6 kampanii, latch po utracie pakietów, regresje). Nie używać1136 jako wyniku finalnej geometrii.
4. Powtórzyć pełne pary LAN Normal/Relaxed na finalnych danych; wymagane zgodne wyniki,
   zdrowie, maski0/5/6 i brak Simulation u gościa. Harness jest już rozgrzewany przed
   handshake (normalna aplikacja również robi load_boot); pomocniczy Python czeka na bind hosta.
5. Powtórzyć natywne preview po ostatniej korekcie; obejrzeć nowe Garden3/Reactor3,
   fields-empty i blocked-contact; upewnić się, że wszystkie13 etapów i2 dodatkowe obrazy aktualne.
6. Ponowić świeży import/eksporty Linux i Windows po korekcie danych; oddzielne katalogi/PCK.
   Linux:boot,pary ENet,natywne F2. Windows runtime NOT RUN (brak Windows/Wine).
7. Zakończyć dokumentację: PROJECT_STATUS nadal opisuje PRZEDM11c i musi zostać zastąpiony.
   M11C_POZIOMY_I_WSPOLPRACA i RAPORT_ROZGRYWKI powstały PRZED korektą brzegów:
   tabele i część opisów zawierają stare S2/pozycje i1136PASS. Zaktualizować, nie zostawić ich jako aktualnych.
   Szczególnie ścieżka dash w ogrodzie: teraz cel podejścia S2=(1056,512);
   start(1120,448), dystans≈90,5, końce bezpieczne; obecny test wykazuje korzyść zrywu.
   Bezpieczne obejście z(1104,384): (1168,384)→(1168,576)→(1056,576)→(1056,512),
   do sprawdzenia w opisie/rysunku. Faza2 P1=(944,624), nie(1168,480).
   Reactor faza2 P1=(1168,512), nie592.
8. Zaktualizować README (pierwsze akapity mają starą etykietęM11a/b), GAME_DESIGN,
   macierz manualną18 konfiguracji i aktualny raport dla AI. Protokół i ADR już rozszerzono,
   ale ich opis dowodów/1136 trzeba uaktualnić. NIE zmieniać historycznych dowodów na fikcyjne PASS.
9. Summary JSON, manifest --check i przegląd logów błędów. Oczekiwany negatywny ENet
   "Couldn't create an ENet host" w teście zajętego portu nie oznacza regresji.
10. Końcowa odpowiedź: zmiany, różnice map, udział obu osób, wykonane testy,
    ludzkie playtesty0/5/NOT RUN, fizyczne2maszyny/Windows runtime/M15perf NOT RUN. M12 nietknięty.

## Polecenia i narzędzia

`/home/pablo/.local/bin/godot --headless --path . --script tools/validate_content.gd`
`... --script tools/record_success_fixtures.gd -- --map=garden` (lub reactor/dock)
`python3 tools/check_charge_windows.py`
`python3 tools/check_field_routes.py`
`... --script tests/test_runner.gd -- --suite=all`
`... --script tools/build_manifest.gd -- --write` po zmianach app/core/net/data; na końcu --check.
`godot --path . --script tools/map_puzzle_preview.gd --max-fps 60`

Pomocniki z /tmp zabezpieczono jako tekst w docs/reports/m11c/resume_helpers/:
- m11c_lan_pair.py.txt: zapisać z powrotem do/tmp, uruchomić --difficulty=0/1.
  Unikalne porty28301/28401, timeout500s, czeka na faktyczny bind hosta.
- m11c_export_smoke.py.txt: kopia projektu do temp, import sekwencyjny,
  eksporty oddzielnie ~/.local/share/lumen-tools/m11c-smoke/linux oraz windows,
  Linux boot/LAN na25991. Używa istniejących pinned templatek (zainstalowane4.5.2).
- m11c_export_native.py.txt + m11c_capture.py.txt: natywne F2/screenshot/close przez X11.
- m11c_docs.py.txt: roboczy generator dokumentacji, WYMAGA aktualizacji opisów nowej geometrii.
  UWAGA: ponowny bieg dopisuje ADR/CODE_CONTRACTS/ARCHITECTURE/README drugi raz.
  Usunąć poprzednie dodane sekcje przed przebudową albo naprawić idempotencję.
- m11c_focus/geometry/hazards.gd.txt: krótkie runnery wybranych suite.

Wszystkie trwałe implementacje są w repo (tools/build_m11c_maps.py,
solution_driver.gd, record_success_fixtures.gd itd.). Narzędzie generatora map
nie jest runtime. Przy wznawianiu nie zaczynać od odtworzenia starych wnęk.

# M11c — instrukcja sprawdzenia ręcznego

## Uruchomienie

Z katalogu projektu:

```bash
/home/pablo/.local/bin/godot --path /home/pablo/lan_game
```

F2 zaczyna lokalną kampanię od doku, seed0/Normal. P1: WASD/strzałki, Spacja,E,Q.
P2: IJKL,Shift,U,O. Po sektorze klawisze1 i2 potwierdzają oba sloty.
Escape pokazuje menu, ale czas i zagrożenia nadal działają. F2 resetuje kampanię.

LAN: dwie instancje z tym samym projektem/protokołem2. Host tworzy pokój,
gość wpisuje IP hosta (127.0.0.1 na jednym komputerze). Obaj gotowi, host Start.
Każdy używa WASD/Spacji/E/Q w swoim oknie; na jednym komputerze reaguje okno
z fokusem. Relaxed i seed wybiera host w formularzu/lobby. Nie używaj starego eksportu.

## Kolejność sprawdzenia

- [ ] Dock1: proste przeciągnięcie przez cel bez E/pól, potem następny cel.
- [ ] Dock2: jeden dron nad kanałem, drugi po prawej; założenie zaczepu daje zasilanie.
      Sprawdź różnicę po odpięciu i gdy oba drony idą razem.
- [ ] Dock3: różne pola; jedno puste albo DASH przerywa ładowanie. Unik pulsu i powrót.
- [ ] Garden1: osiągnij150, odejdź z pól, odczekaj; postęp nie powinien spaść poniżej150.
      Przejdź na widoczną drugą parę i dokończ. Zamieńcie role.
- [ ] Garden2: obejdź blok gniazdem, przerwij ustawienie przed SWEEP i wróć.
- [ ] Garden3: po150 zmień oba stanowiska oraz S1→S2. Porównaj obejście z krótką
      drogą przy pulsie. Próbuj zachować stary zaczep lub ominąć go przy brzegach pól.
- [ ] Reactor1: oddzielne stanowiska po bokach przeszkody, SWEEP i miejsce odwrotu.
- [ ] Reactor2: po150 przestawcie oboje drony; reagujcie na kolejne ostrzeżenia pulsów.
- [ ] Reactor3: oba etapy, zmiana S1→S2, PULSE i SWEEP; po300 wspólne wyjście2 s.
- [ ] LAN: sprawdź zgodność etapów, zdrowia i wyniku u obu osób oraz reset pól na kolejnym sektorze.
- [ ] Sprawdź, czy podpowiedzi wyjaśniają brak zasilania, przyszła para jest widoczna,
      a czerwony X wskazuje faktycznie blokowaną część przewodu.

Dla całej macierzy przejdź kampanie z seed0,1,2 w Normal i Relaxed:6 kampanii
obejmuje18 kombinacji sektor/faza/trudność. To warianty faz, nie nowe układy map.
Nie trzeba zaczynać od całej macierzy — pierwszy przebieg ma ocenić zrozumiałość.

Zapisz przy problemie: mapę/cel/etap, seed/trudność, pozycje i aktywny zaczep,
co robiła każda osoba, stan ładunku oraz czy problem dotyczył sterowania, zasad
czy czytelności. Rozwiązania ze współrzędnymi są w M11C_POZIOMY_I_WSPOLPRACA.md.
Aby ocenić intuicyjność, pierwszy przebieg zrób bez czytania tych rozwiązań.

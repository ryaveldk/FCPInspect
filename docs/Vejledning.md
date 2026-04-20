# FCPInspect — Vejledning

Diagnostisk værktøj til Final Cut Pro-biblioteker. Den første version finder
spøgelses-multicams (ghost multicams): duplikerede master-objekter der opstår
når man match-framer på en multicam hvor timeline-referencen er ude af sync
med masteren.

---

## 1. Hvorfor opstår ghost-multicams?

Når du match-framer (Shift+F) på en multicam-instans i timelinen, sammenligner
Final Cut Pro den cachede snapshot-data i projektet med den aktuelle master. Er
de ude af sync — typisk fordi masteren er blevet ændret efter instansen blev
lagt i timeline — opretter FCP stille og roligt en *parallel* master-kopi med
samme angle-struktur men en ny UID.

Det bliver ikke vist i UI'en. Det eneste symptom du ser:

- Biblioteket vokser uforklarligt i størrelse
- Performance forringes
- Multicam Info-panelet viser sommetider en anden modDate end forventet
- Event-browseren har duplikater med "Multicam 1", "Multicam 2" suffikser

Fordi snapshot-dataen *ikke* skrives til FCPXML, forsvinder problemet ved en
round-trip (eksport → import i friskt bibliotek).

---

## 2. Installation (første gang)

1. Åbn `FCPInspect-0.1.0-universal.dmg`
2. Træk `FCPInspect.app` over på `Applications`-symlinket i DMG'en
3. I Applications-mappen: **højreklik på FCPInspect.app → Åbn**
   (IKKE dobbeltklik første gang — det bliver blokeret af Gatekeeper)
4. Accepter advarslen "Open anyway". Fra nu af virker normal dobbeltklik.

Hvis macOS alligevel siger `er beskadiget og kan ikke åbnes`:

```bash
xattr -dr com.apple.quarantine /Applications/FCPInspect.app
```

Og prøv igen.

---

## 3. Sådan finder du ghost-multicams

### A. Eksportér FCPXML fra Final Cut Pro

Du har to muligheder — vælg den der matcher hvad du mistænker:

**Hele biblioteket (mest grundige scan):**

1. Marker biblioteket i sidebaren
2. `File → Export XML…`
3. FCPXML Version: **1.10 eller nyere**
4. Gem filen et sted du husker

**En enkelt suspekt multicam:**

1. Højreklik på multicam-clippet i event-browseren
2. `Export XML…`
3. Gem den

Eksportér gerne alle mistænkte multicams hver for sig hvis du vil sammenligne
dem, eller hele biblioteket på én gang for den komplette scan.

### B. Kør FCPInspect

1. Start FCPInspect
2. Træk en eller flere `.fcpxml`-filer eller `.fcpxmld`-bundles ind i vinduet.
   Du kan også trække en hel mappe ind — den bliver scannet for alle
   FCPXML-filer.
   (Alternativt: `File → Open…` eller ⌘O)
3. Checken kører automatisk. Finder den noget, dukker et gult varslings-prik
   op i sidebaren ud for "Multicam Duplication".
4. Klik på fundet i midter-panelet for at se detaljerne til højre.

### C. Læs rapporten

For hvert fund viser FCPInspect:

- **Authoritative master** — den kopi med nyeste `modDate`. Det er den du
  vil beholde. Navnet står øverst, UID og modDate vises.
- **Ghost duplicates** — de ældre kopier. Det er dem der skal væk.
- **Suggested remediation** — den konkrete procedure (se næste afsnit).
- **XML locations** — hvor i filen hver master ligger, hvis du vil inspicere
  rå-XML'en manuelt.

Hvis der er flere medias med samme angle-fingerprint men forskellige UIDs,
er der tale om ghost-multicams. Er der kun ét match eller identisk UID, så
har du ikke et duplet-problem — mindst ikke som denne check kan detektere.

---

## 4. Sådan retter du op

FCPInspect rører **aldrig** dit bibliotek — det læser kun XML. Du skal selv
udføre reparationen. Princippet er enkelt: den korrupte snapshot-data lever
kun i bibliotekets intern database. En round-trip gennem FCPXML renser det.

### Fremgangsmåde

1. **Luk dit projekt** i FCP og sørg for at biblioteket ikke er åbent andre
   steder.
2. **Backup biblioteket** — altid. Dupliker `.fcpbundle`-mappen i Finder og
   mærk den `_BACKUP_før-multicam-fix`.
3. **Eksportér det ramte projekt** fra FCP: marker projektet →
   `File → Export XML…` → FCPXML 1.10+. Gem som fx
   `MitProjekt_fix.fcpxml`.
4. **Opret et nyt, tomt bibliotek**: `File → New → Library…`. Kald det fx
   `MitBibliotek_renset`.
5. **Importér FCPXML'en** i det nye bibliotek: `File → Import → XML…` og vælg
   den fil du eksporterede i trin 3.
6. FCP genopbygger projektet fra XML'en. Eventuelle ghost-multicams er nu
   *ikke* blevet kopieret over, fordi snapshot-dataen kun lå i det gamle
   bibliotek.
7. **Verificér:** eksportér det nye projekt som FCPXML, kør det gennem
   FCPInspect igen. Rapporten skal nu sige `No findings ✅`.
8. Arbejd videre i det rensede bibliotek. Arkivér det gamle eller slet det
   når du har kørt et par dage uden problemer.

### Hvad du **ikke** skal gøre

- **Slet ikke manuelt i `.fcpbundle`**-mappen. Det virker ikke og kan
  korruptere biblioteket permanent.
- **Duplicer ikke events mellem biblioteker** for at "lave et rent eksemplar".
  Det kopierer snapshot-dataen med.
- **Stol ikke blindt på FCP's eget Consolidate/Relink** — det retter ikke
  ghost-multicams, kun manglende medier.

---

## 5. Hvad FCPInspect ikke gør (pr. version 0.1)

- Scanner ikke `.fcpbundle`-biblioteker direkte. Du skal eksportere FCPXML
  først.
- Rører ikke dine mediefiler. XML-only.
- Retter ikke automatisk. Du udfører selv round-trip'en manuelt.
- Understøtter kun FCPXML 1.10–1.14 officielt. Ældre filer kan parses men er
  ikke testet.
- Finder kun ghost-multicams. Andre strukturelle problemer (duplikerede
  assets, orphan clips, compound clip inconsistencies osv.) kommer i senere
  versioner.

---

## 6. Fejlfinding

**App'en siger `kan ikke åbnes fordi udvikleren ikke kan verificeres`**  
Højreklik → Åbn → Open Anyway. Sker kun første gang.

**App'en siger `er beskadiget og bør flyttes til papirkurven`**  
Quarantine-flag. Kør:
```bash
xattr -dr com.apple.quarantine /Applications/FCPInspect.app
```

**Rapporten viser 0 findings, men jeg ved der er ghost-multicams**  
Sandsynlige årsager:
- Du har kun eksporteret én multicam — checken kan ikke sammenligne mod
  andre. Eksportér hele biblioteket eller alle mistænkte multicams sammen.
- De har forskellige angle-sæt (fx en af dem er blevet redigeret). Checken
  kræver *identisk* angle-fingerprint.
- Det er faktisk ikke et ghost-problem — kan være noget andet.

**Rapporten melder false positive**  
Hvis to multicams tilfældigt har præcis samme angle-ID'er uden at være
dupletter af hinanden, kan checken rapportere dem. Det er usandsynligt i
praksis (angle-ID er random genereret), men hvis det sker: brug modDate og
UID til at afgøre om det er samme master. Forskellig modDate med flere
måneder mellem dem → sandsynligvis samme master.

**App'en crasher eller viser ingen findings overhovedet på store biblioteker**  
Rapportér det — send FCPXML-filen til udvikleren hvis muligt. Milestone 1 er
testet på filer op til ~10 MB.

---

## 7. Support

Denne version er et internt test-build. Feedback og bug-rapporter gerne til
udvikleren.

Version: 0.1.0  
GitHub: https://github.com/ryaveldk/FCPInspect

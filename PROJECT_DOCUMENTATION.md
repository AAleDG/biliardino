# Documentazione progetto Biliardino

## Scopo del progetto

Biliardino e' una app Flutter pensata per tracciare le partite di biliardino in ufficio. L'obiettivo e' avere uno strumento rapido per:

- gestire i giocatori disponibili;
- segnare chi e' presente in ufficio;
- comporre squadre 1 vs 1 o 2 vs 2;
- registrare il punteggio di una partita;
- salvare lo storico dei risultati;
- consultare classifica e statistiche base.

Il tono dell'app resta interno e operativo. Il tema South Africa 2010 usa fondo avorio, titoli Barlow Condensed, nastri colorati e sagome di biliardino. La specifica approvata e' in [DESIGN.md](DESIGN.md). L'estensione Home approvata cambia l'organizzazione della navigazione, ma mantiene raggiungibili tutti i comportamenti esistenti.

## Come e' stato creato

Il progetto e' una applicazione Flutter multi-piattaforma con persistenza locale SQLite tramite `sqflite`.

Stack principale:

- Flutter/Dart.
- `flutter_bloc` e `bloc` per gestione stato tramite Cubit.
- `equatable` per stati e filtri confrontabili.
- `sqflite` per database locale.
- `uuid` per generare id di giocatori e partite.
- `intl` per formattare date e orari.

Struttura attuale:

- `lib/main.dart`: inizializza Flutter, repository, database e provider globali.
- `lib/data/database_helper.dart`: apre `biliardino.db` e crea le tabelle `players` e `matches`.
- `lib/models/`: contiene i modelli principali (`Player`, `GameMatch`, `PlayerStats`).
- `lib/repositories/`: incapsula accesso e cache a giocatori e partite.
- `lib/cubits/`: contiene la logica di stato per home, giocatori, nuova partita, storico e classifica.
- `lib/screens/`: contiene le schermate utente.
- `lib/services/stats_service.dart`: concentra funzioni pure per nomi giocatori, ordinamento partite e classifica.
- `lib/widgets/`: contiene componenti riusabili come avatar e celebrazioni.
- `test/widget_test.dart`: copre avvio app, overflow su schermo piccolo e comportamenti dello storico.

La persistenza locale usa due tabelle:

- `players`: `id`, `name`, `created_at`, `is_present`.
- `matches`: `id`, `played_at`, quattro player id per le squadre, punteggi e squadra vincente.

## Flusso applicativo

Lo stato implementato prima dell'estensione Home usa una bottom navigation con cinque sezioni:

- **Giocatori**: elenco giocatori, stato presenza, aggiunta nuovo giocatore.
- **Partita**: composizione squadre, avvio partita, scoreboard, modifica punteggio, salvataggio risultato.
- **Storico**: registro partite con riepilogo, filtri, gruppi per data e card risultato.
- **Classifica**: ranking generale e marcatori separati per 1vs1 (giocatori) e 2vs2 (coppie), calcolati dalle partite salvate.
- **Dati**: esportazione JSON/CSV e ripristino verificato tramite i selettori nativi.

La fondazione implementata per l'estensione Home usa cinque voci primarie tipizzate:

- **Home**: dashboard iniziale con azione avvia/riprendi, cinque risultati recenti non filtrati e quattro posizioni della classifica.
- **Giocatori**: gestione completa dei giocatori e della presenza.
- **Partita**: setup e partita attiva esistenti.
- **Classifica**: classifica completa e profili.
- **Altro**: accesso tramite route complete a **Storico** e **Dati**, mantenendo filtri e comportamenti esistenti.

**Dati** raggruppa **Crea backup** (JSON) ed **Esporta risultati** (CSV) sotto ESPORTA, e **Ripristina backup** sotto RIPRISTINA. Le schede Pass condividono la presentazione con Altro e mantengono un’unica azione accessibile. `DataManagementCubit` coordina le operazioni tramite una dipendenza iniettata; picker, condivisione e conferma restano effetti della presentazione. Il ripristino verifica il file prima della conferma e sostituisce i dati atomicamente. Se il successivo aggiornamento dei repository fallisce, il messaggio distingue il ripristino già avvenuto e permette di ritentare soltanto l’aggiornamento. Aprire il foglio di condivisione non certifica che il backup sia stato salvato. La lettura del file e la decodifica UTF-8 avvengono su worker nativi; il limite resta 10 MiB. Il coordinatore analizza e valida il JSON in un isolate tramite un callback statico che non trasferisce il database. Il Cubit consuma il risultato del picker prima di attendere il parser, mantiene l'operazione occupata e ignora risultati dopo la chiusura. Il ripristino esegue inserimenti in batch di massimo 500 righe, senza raccogliere risultati inutilizzati: tutti i batch appartengono alla stessa transazione, con giocatori prima delle partite. Un errore annulla anche cancellazioni e batch precedenti; le impostazioni restano intatte.

`HomeCubit` espone `HomeDestination` invece di indici numerici. `HistoryCubit` vive sopra le route, cosi' i filtri sopravvivono alle visite da **Altro**. `DashboardCubit` e' alimentato direttamente dagli stream di `PlayerRepository` e `MatchRepository`: riusa `StatsService.sortedByMostRecent` e `StatsService.computeLeaderboard`, limita i risultati a cinque e le posizioni giocate a quattro, e non possiede persistenza, filtri dello storico o una nuova formula punti. La Home usa l'hero H2 approvato come PNG trasparente decorativo: e' l'unico elemento a tutta larghezza, conserva il rapporto intrinseco 1516:1038 e non usa crop. Wordmark, tagline, azione avvia/riprendi, righe, link e navigazione restano widget Flutter. L'azione Home e' una variante locale a capsula da 72dp con bordo bianco, ombra contenuta e lockup Barlow Condensed; non modifica i pulsanti condivisi delle altre schermate. Le righe hanno target da almeno 48dp, quindi la pagina scorre invece di comprimere la classifica sotto i risultati; con testo ingrandito le intestazioni si impilano e la barra primaria mantiene cinque destinazioni stabili.

All'avvio `BiliardinoBootstrap` carica giocatori, partite, regole e preferenza di presentazione; in caso di errore permette di ritentare con gli stessi repository. `BiliardinoApp` espone i repository tramite `MultiRepositoryProvider` e crea i Cubit globali principali, inclusi `DashboardCubit` e il `HistoryCubit` condiviso dalle route.

### Selezione della presentazione a runtime

`AppPresentation`, risolta da `presentationFor(AppStyle)`, registra `southAfrica2010` e `italia90`. Ogni adapter possiede tema, chrome, composizioni e politica di navigazione originali. Il codice visuale Italia vive in `lib/presentation/italia90`; Anton e la famiglia `Italia Barlow` mantengono i pesi del donor senza modificare i font South Africa. Le due presentazioni condividono i repository, i Cubit globali, il database e il Navigator; non condividono i rispettivi disegni del podio.

`AppStyleRepository` usa `appearance.style` nella tabella settings esistente, senza migrazione. Valori mancanti o sconosciuti mostrano South Africa senza riscrittura durante il caricamento. `AppStyleCubit` pubblica una scelta solo dopo il salvataggio riuscito. Il ripristino dei dati di gioco preserva la preferenza e le altre impostazioni locali.

**Altro → Aspetto** apre una route senza barra dei tab. Le schede cambiano subito lo stile dopo la persistenza, restando sulla stessa route. `AppearanceScreen` mantiene lo Stato durante il cambio della cornice; errori permettono di ritentare. AppStyleCubit rende osservabile la scelta pendente per tutta la scrittura: tornare ad Altro e riaprire Aspetto conserva il blocco delle richieste concorrenti fino al completamento, anche in caso di errore. I preview riusano solamente artwork decorativo e widget, senza istanziare Home, bootstrap o proprietari funzionali.

`AppPresentationScope` avvolge `MaterialApp`; `PresentationPage` e `PresentationBuilder` risolvono le route attraverso gli adapter. `PresentationHost` conserva le shell già visitate, ciascuna con il proprio tema: controller, scroll e la pagina Dati nascosta di Italia non vengono distrutti dal cambio. I ticker inattivi sono disabilitati; soltanto la presentazione attiva consuma effetti globali e gestisce il back della shell. `RankingTabs` sincronizza Generale/Marcatori tramite `LeaderboardCubit.selectedTab`, insieme al modo 1vs1/2vs2 condiviso. Non usare lo stile come chiave di MaterialApp o del Navigator.

South Africa conserva Storico/Dati come route spinte; Italia conserva le destinazioni nascoste della shell. `PresentationOperations`, sopra il Navigator, osserva i Cubit Dati locali senza consumarne gli effetti: Aspetto attende finché un export/picker/ripristino o un aggiornamento richiesto sono pendenti. Il proprietario originale completa ogni effetto una volta. La scelta pubblica è disponibile solo da Altro; editor, profili, modali e partita attiva mantengono le loro regole di uscita originali, senza un selettore globale che aggiri una bozza o annulli una partita.

La verifica usa entrambe le vere presentazioni, persistenza SQLite, identità dei proprietari/Navigator, setup, filtri e tab di Classifica, operazioni pendenti, errori e disposal. Le immagini Italia originali restano archiviate: tre catture con decode incompleto o il difetto di nome obsoleto sono affiancate da riferimenti corretti prodotti indipendentemente dal codice donor invariato. Solo Altro e la nuova pagina Aspetto aggiungono UI; i calcoli e l’export Classifica restano quelli corretti in R5.

La verifica finale e i limiti mantenuti sono documentati in `design/runtime-style-selection/IMPLEMENTATION.md`. Il piano temporaneo rimane ignorato fino alla conferma del landing sul ramo primario; AGENTS.md viene preservato verbatim come richiesto dall’utente.

### Feedback nell’app

**Altro → Invia feedback** apre una route completa in entrambe le presentazioni, con messaggio obbligatorio ed email facoltativa. `FeedbackScreen` conserva controller e Cubit durante i rebuild dello stile. `FeedbackPageFrame` applica i token esistenti e i soli sfondi R2 approvati; testo, logo, campi e controlli restano widget Flutter. La cornice scorre con tastiera e testo ingrandito.

`FeedbackRepository`, creato in modo lazy, salva una sola bozza condivisa tra gli stili nella chiave `feedback.draft.v1` della tabella settings. Le scritture serializzate includono la cancellazione dopo un invio riconosciuto; una scrittura fallita non interrompe la coda. La chiusura attende il salvataggio e, se fallisce, consente di restare o chiudere consapevolmente. Le notifiche distinguono salvataggio in corso, errore e bozza salvata.

`FormspreeFeedback` invia JSON HTTPS a `https://formspree.io/f/meaerkro`: messaggio, eventuale email, versione/build, piattaforma e stile scelto. Non invia dati di giocatori o partite. I metadati hanno un timeout di 5 secondi; la richiesta HTTP ha una scadenza di 20 secondi e chiude sempre il client. Il trasporto non segue redirect e accetta solo una risposta JSON 2xx con `next` stringa, senza errori o challenge. Il form blocca modifiche, invii concorrenti e Back fino all’esito; il retry è manuale. Un esito riconosciuto mostra “Grazie! Feedback inviato.” e “Torna ad Altro”; un errore di cancellazione locale della bozza non diventa un errore di invio.

Il form Formspree deve avere reCAPTCHA disabilitato e nessuna restrizione Referer/Domain per questo client nativo. L’acknowledgement HTTP non dimostra una voce nell’inbox: la verifica di consegna richiede un riscontro separato. Il perimetro di questa versione è iOS/Android; la consegna macOS non è supportata/verificata. Stato ed evidenze dell’incremento sono in `design/feedback/IMPLEMENTATION.md`.

## Motivazioni delle scelte tecniche

### Flutter

Flutter e' stato scelto perche' permette di costruire rapidamente una app mobile con interfaccia ricca, animazioni fluide e comportamento coerente su piu' piattaforme. Per un progetto interno come questo e' una scelta pragmatica: una sola codebase, UI nativa abbastanza performante e tooling gia' disponibile nel progetto.

### Persistenza locale con SQLite e `sqflite`

Le partite e i giocatori sono dati locali, piccoli e strutturati. Per questo e' stato scelto SQLite invece di un backend remoto:

- non serve autenticazione;
- l'app funziona anche senza rete;
- il modello dati e' semplice;
- la latenza e' praticamente nulla;
- non ci sono costi o infrastruttura da mantenere.

`sqflite` e' una scelta naturale in Flutter quando serve un database relazionale locale. Le tabelle `players` e `matches` sono volutamente esplicite e semplici, perche' le query necessarie sono poche e la logica piu' importante viene calcolata in Dart.

### Repository

`PlayerRepository` e `MatchRepository` isolano il database dal resto dell'app. Questa scelta evita che le schermate conoscano dettagli come nomi tabelle, query SQL o ricaricamenti da SQLite.

I repository mantengono anche una cache in memoria e pubblicano stream broadcast. Le liste pubblicate sono snapshot immutabili: Dashboard, Classifica, Storico e Profilo ignorano la ripetizione dello stesso snapshot iniziale per identita', ma ricalcolano sulle nuove pubblicazioni, compresi rinomina, archiviazione e ripristino. In questo modo piu' Cubit possono reagire agli stessi cambiamenti: ad esempio, salvare una partita aggiorna sia storico sia classifica senza far comunicare direttamente le schermate tra loro.

### Bloc/Cubit

La gestione stato e' stata spostata su Cubit per separare intenzioni utente, stato derivato e UI. Questa scelta rende il progetto piu' ordinato rispetto a tenere tutta la logica dentro widget stateful.

Esempi:

- `NewMatchCubit` gestisce composizione squadre, punteggio, validazione e salvataggio. Possiede anche il riepilogo storico del duello: gol e correzioni lo riusano, mentre nuove partite o squadre diverse lo invalidano. Schermata live e opzioni leggono lo stesso riepilogo.
- `HistoryCubit` gestisce filtri, partite filtrate e gruppi per data.
- `LeaderboardCubit` ricalcola la classifica quando cambiano giocatori o partite.

Il vantaggio principale e' che le schermate diventano piu' dichiarative: leggono uno stato e inviano comandi al Cubit. Il costo e' un po' piu' di struttura iniziale, ma il progetto resta piu' facile da estendere.

### `Equatable`

`Equatable` e' usato per confrontare stati e filtri in modo affidabile senza scrivere manualmente operatori `==` e `hashCode`. Questo e' utile soprattutto per evitare rebuild o ricalcoli inutili quando i filtri dello storico non sono realmente cambiati.

### Logica derivata in servizi e file dedicati

La classifica, i nomi giocatore, l'ordinamento delle partite e i filtri dello storico sono calcoli derivati dai dati salvati. Per questo sono stati messi in funzioni pure (`StatsService`, `history_logic.dart`) invece che direttamente nei widget.

Questa scelta ha tre motivi:

- rende la UI piu' leggibile;
- riduce duplicazione;
- facilita i test, perche' la logica puo' essere verificata senza dipendere dal rendering Flutter.

### Filtri dello storico

I filtri dello storico sono stati messi in un bottom sheet invece che in una lunga barra di chip sempre visibile. La motivazione e' di prodotto e di layout:

- lo storico resta leggibile;
- i filtri non rubano spazio alla lista partite;
- c'e' posto per opzioni piu' ricche come periodo, giocatore e risultato;
- il layout scala meglio quando aumentano i giocatori.

Il filtro `Vinte/Perse` viene abilitato solo quando e' selezionato un giocatore, perche' senza un giocatore non avrebbe un significato chiaro.

### Classifica calcolata, non salvata

La classifica non viene persistita nel database. Viene calcolata dalle partite salvate. Questa scelta evita dati duplicati e possibili inconsistenze: se una partita esiste nello storico, la classifica puo' sempre essere ricostruita.

`LeaderboardCubit` conserva la modalita' selezionata in memoria: sceglie 2vs2 all'apertura se esistono partite 2vs2, altrimenti 1vs1, e non cambia scelta durante rinomina, archiviazione o correzioni. Solo questa proiezione filtra le partite per modalita'; Dashboard e profilo individuale continuano a usare tutte le partite.

Nel 2vs2 `StatsService.computeTeamLeaderboard` aggrega ogni coppia ricorrente senza distinguere ordine dei membri o lato del campo. L'identita' derivata codifica in JSON gli ID ordinati, preservando anche ID importati con delimitatori; non e' salvata e non richiede migrazioni. Generale ordina per tre punti a vittoria, win rate e nome; Marcatori somma i gol attribuiti ai membri e ordina per gol, partite e nome. I risultati legacy senza marcatori non inventano gol. Gli snapshot includono i nomi e proteggono liste e cronologia dei marcatori.

`RankingStats` espone i dati comuni per i widget live senza rappresentare una coppia come giocatore fittizio. I target coppia passano da `openPairProfile` e `AppPresentation.pairProfile`; il `PairProfileCubit` della route segue gli stessi repository, conserva membri archiviati, statistiche, avversari e tutte le partite insieme. Entrambi i membri aprono il proprio profilo. Il CSV esporta sempre Generale nella modalita' selezionata, anche dalla scheda Marcatori.

Il tradeoff e' che la classifica viene ricalcolata quando cambiano partite o giocatori, ma per il volume dati previsto da una app da ufficio il costo e' trascurabile.

### UI dark e palette NTT-like

La UI usa un tema dark con accenti ciano/arancio per mantenere un'identita' visiva coerente e distinguere le squadre. I colori sono centralizzati in `AppTheme`/`NttColors` per evitare valori sparsi e rendere piu' semplice eventuali modifiche future.

### Test widget

I test widget sono stati scelti per validare i flussi principali dal punto di vista utente:

- l'app si avvia;
- le schermate principali non generano overflow su schermo piccolo;
- lo storico mostra gruppi data e filtri corretti.

La scelta di testare overflow e nomi lunghi deriva dal tipo di app: i nomi dei giocatori possono essere lunghi e l'uso su telefono richiede layout robusti.

## Prompt noti o ricostruiti

Questa sezione contiene i prompt che risultano dalla conversazione recente. Non e' un audit completo di tutta la storia del progetto: dove non ho il testo esatto, il prompt e' indicato come ricostruito.

Prompt iniziale/progetto, ricostruito:

> Crea una app Flutter per tracciare partite di biliardino in ufficio, con gestione giocatori, presenze, composizione squadre, registrazione risultati, storico e classifica.

Prompt per migliorare lo storico, noto:

> bisogna fare in modo che la pagina riguardo allo storico delle partite non sia cosi vibe coded. Hai qualche idea per migliorare e/o proposte per abbellire tutto cio?

Prompt per pianificare il redesign dello storico, noto:

> ok pianifica cio, fai dividi tutto in varie fasi ed esegui una dopo l'altra le varie fasi

Prompt di implementazione del redesign storico, noto:

> PLEASE IMPLEMENT THIS PLAN: Redesign Sobrio Dello Storico Partite

Il piano richiesto prevedeva:

- rimozione della timeline decorativa;
- header riepilogativo;
- filtri piu' puliti;
- lista raggruppata per data;
- card risultato piu' leggibili;
- empty state differenziato;
- test e validazioni.

Prompt per migliorare i filtri, noto:

> forse bisognerebbe implementare meglio la pagina in merito ai filtri, no? prima di procedere alle modifiche, discuti con me, cosa miglioreresti ?

Prompt di approvazione dei filtri, noto:

> ok prova

Prompt per questa documentazione, noto:

> vedendo un po' tutto quello che e' stato creato all'interno del progetto, puoi creare un file md dove racchiudi: lo scopo del progetto, com'e' stato creato, i vari prompt usati, varie features implementate. Cerca di essere preciso ed accurato

## Feature implementate

### Gestione giocatori

- Lista giocatori ordinata.
- Aggiunta nuovo giocatore tramite dialog.
- Stato presenza con switch.
- Riepilogo presenti/totale.
- Indicazione se ci sono almeno 2 presenti per giocare (1v1).
- Avatar generato dalle iniziali/nome del giocatore.

### Nuova partita

- Composizione manuale di due squadre da due giocatori.
- Vincolo di almeno quattro giocatori presenti.
- Selezione squadra 1 / squadra 2 per ogni giocatore presente.
- Avvio partita solo quando le squadre sono valide.
- Scoreboard per partita in corso.
- Incremento e decremento gol per squadra.
- Modifica manuale del punteggio tramite dialog.
- Reset punteggio.
- Conferma prima di abbandonare una partita in corso.
- Validazione salvataggio: niente pareggi e niente partite 0-0.
- Salvataggio risultato nel database.
- Feedback haptico in alcune azioni.
- Celebrazioni visuali per gol e vittoria.

### Storico partite

La correzione usa la schermata **Distinta**, accessibile dalle azioni della card e dal dettaglio partita. Ogni squadra riunisce giocatori, risultato finale e gol attribuiti. In 2v2 si modificano i conteggi dei singoli marcatori; in 1v1 i gol mancanti richiedono una conferma esplicita. Cambiare punteggio o giocatore non assegna automaticamente i gol mancanti. Le incongruenze devono essere risolte prima del salvataggio. Rivalità rimane visibile per 1v1 e può essere rimossa dai record 2v2 già contrassegnati.

Le modifiche restano in una bozza fino al salvataggio tramite HistoryCubit e MatchRepository. Annullare una bozza modificata richiede conferma; un errore di salvataggio mantiene la bozza per riprovare. La data e l'ora hanno selettori dedicati, i punteggi consentono anche l'inserimento numerico e la sostituzione dei giocatori usa un elenco ricercabile. Non è presente un menu Altre opzioni.

- Registro risultati con header riepilogativo:
  - numero partite filtrate;
  - ultima partita;
  - filtri attivi.
- Lista raggruppata per giorno.
- Label data in italiano:
  - `Oggi`;
  - `Ieri`;
  - data estesa come `17 giugno 2026`.
- Card partita con:
  - orario;
  - squadre;
  - punteggi;
  - evidenza della squadra vincente;
  - label `Vittoria`.
- Bottom sheet filtri con:
  - periodo (`Tutti i risultati`, `Oggi`, `Ultimi 7 giorni`, `Ultimi 30 giorni`);
  - giocatore;
  - risultato (`Tutte`, `Vinte`, `Perse`), abilitato solo quando un giocatore e' selezionato.
- Barra filtri compatta nella pagina.
- Reset rapido dei filtri.
- Empty state diverso tra nessuna partita generale e nessun risultato trovato con filtri attivi.
- Logica storico separata in:
  - `history_filters.dart`;
  - `history_logic.dart`;
  - `history_cubit.dart`;
  - `history_state.dart`.

### Classifica

- Classifica derivata dalle partite salvate.
- Calcolo partite giocate, vittorie, sconfitte e punti.
- Ordinamento per punti, poi win rate, poi nome.
- Podio per i primi classificati.
- Lista completa per gli altri giocatori.
- Stato vuoto quando non ci sono partite.

### Navigazione e UI

- Splash screen iniziale.
- Bottom navigation con indicatore animato.
- Tema dark centralizzato in `AppTheme`.
- Palette NTT-like:
  - blu primario;
  - ciano/accent;
  - arancio per squadra 2;
  - superfici dark.
- Material 3
- Componenti con animazioni leggere.
- Attenzione a overflow e nomi lunghi nei test widget.

### Architettura e stato

- Repository per isolare database e cache:
  - `PlayerRepository`;
  - `MatchRepository`.
- Stream broadcast dai repository per aggiornare Cubit dipendenti.
- Cubit dedicati:
  - `HomeCubit`;
  - `PlayersCubit`;
  - `NewMatchCubit`;
  - `HistoryCubit`;
  - `LeaderboardCubit`.
- Funzioni pure centralizzate per statistiche e storico.
- Separazione progressiva tra UI, stato, repository e logica derivata.

### Test e validazione

- Test di avvio app.
- Test anti-overflow sulle schermate principali in viewport piccolo.
- Test storico:
  - raggruppamento partite per data;
  - empty state con filtro senza risultati;
  - filtro delle partite vinte da un giocatore.

Comandi di riferimento:

```sh
/Users/alessandroantonio.delgaudio/fvm/versions/3.44.1/bin/dart analyze lib/screens/history_screen.dart test/widget_test.dart
/Users/alessandroantonio.delgaudio/fvm/versions/3.44.1/bin/flutter test
```

## Stato e note tecniche

- Le modifiche sono locali e non committate, salvo eventuali commit fatti manualmente fuori da questa documentazione.
- `flutter test` puo' mostrare warning relativi a Swift Package Manager e `sqflite`; al momento sono warning del tooling/plugin, non errori funzionali della suite.
- Alcuni file del progetto usano ancora `withOpacity`, che le versioni recenti di Flutter segnalano come deprecato a favore di `withValues(alpha: ...)`.
- La documentazione dei prompt e' accurata per la conversazione recente, ma non sostituisce una cronologia completa di tutti i prompt eventualmente usati in sessioni precedenti.


## Tema South Africa 2010 e componenti

`lib/theme/design_tokens.dart` contiene colori semantici, tipografia, spazi e raggi; `app_theme.dart` li applica a Material, inclusi gli stati selezionato, disabilitato, premuto e focus. I font Barlow 400/600 e Barlow Condensed 800/900 sono locali in `assets/fonts/`, con licenze OFL. Non occorrono richieste di rete o pacchetti grafici aggiuntivi.

I componenti in `lib/widgets/design/` ricevono valori e callback. `BrandHeader`/`brandAppBar` e `RibbonBackdrop` gestiscono la decorazione; `AdaptivePair` impila due contenuti quando spazio o scala testo lo richiedono; `LiveMatchView`, `LiveScore` e `LiveTeamCard` in `lib/screens/new_match/` compongono il tabellone illustrato, il punteggio animato e i controlli per squadra; `RankingPodium`/`RankingBadges` condividono la presentazione tra Generale e Marcatori. Avatar, titoli, punteggi e controlli restano widget, non immagini.

I cinque SVG approvati in `design/south-africa-2010/assets/r1/svg/` sono i master. `python3 tool/generate_south_africa_artwork.py` verifica approvazione e SHA-256, quindi compila le primitive consentite in `artwork_paths.dart`. Non modificare quel file generato a mano; modifiche sostanziali all'arte richiedono una nuova revisione approvata. Il painter comune usa le stesse geometrie per intestazioni, splash e celebrazioni.

`motion_policy.dart` centralizza tempi e curve. `MotionAwareState` osserva cambiamenti MediaQuery e accessibilita' di piattaforma anche a runtime. La home limita i ticker alla pagina visibile. Il podium parte alla prima visualizzazione; storico e righe ordinarie non hanno animazioni a cascata. Le celebrazioni restituiscono un handle cancellabile: gol rapidi si sostituiscono, undo/reset/cambio tab/disposal rimuovono gli overlay. Il risultato e le sue azioni non attendono la fine degli effetti. Con movimento ridotto il gol conserva una pausa leggibile statica e coriandoli/traslazioni sono rimossi. Lo splash passa alla home una sola volta quando il bootstrap e' pronto.

Per riprodurre splash/gol/vittoria senza aprire il database, usare `tool/motion_preview.dart` come entry point di sviluppo. Ogni comando verso il simulatore di questa feature deve usare il dispositivo esatto in AGENTS.md. Le schermate compatte e il testo al 200% sono coperti da widget test e goldens con i font reali; queste prove non sostituiscono la verifica di VoiceOver o dei picker/share sheet nativi.

La logica Cubit, le regole, lo schema SQLite, i repository, i calcoli e i servizi di import/export restano i proprietari dei comportamenti. Questa migrazione non introduce un nuovo modello dati, una selezione di temi o il timer della mood board.

Stato della consegna e limiti delle verifiche: [ricevuta South Africa 2010](design/south-africa-2010/IMPLEMENTATION.md). I test automatici coprono il cambio di movimento ridotto a runtime; la verifica nativa e la navigazione VoiceOver restano non verificate e sono state esplicitamente rinviate dall'utente a un successivo hardening di rilascio, senza bloccare il completamento di questo branch.

## Profilo Figurina — South Africa 2010

Il profilo riunisce identita', presenza o stato archiviato, punti e badge in un hero giallo. Un pannello raggruppa le sei statistiche esistenti e la forma recente; seguono intesa e rivalita', confronti diretti e storico personale completo. Nomi, valori e badge restano widget; l'illustrazione e i nastri sono decorativi. Testi ingranditi, nomi lunghi e aree sicure laterali fanno adattare il contenuto senza limitare lo storico.

`PlayerProfileCubit`, limitato alla route e chiuso all'uscita, combina gli aggiornamenti dei repository esistenti usando `StatsService`. `StatsService.playerHistory` seleziona e ordina una sola volta lo storico personale, riutilizzandolo per forma, relazioni e confronti. Il profilo mantiene formule, criteri di parita', gol effettivamente registrati, ordinamento e navigazione precedenti. I punteggi nello storico conservano l'ordine squadra 1–squadra 2 anche quando il giocatore appartiene alla seconda squadra. Le righe di confronto e storico non introducono nuove azioni.

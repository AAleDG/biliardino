# Documentazione progetto Biliardino

## Scopo del progetto

Biliardino e' una app Flutter pensata per tracciare le partite di biliardino in ufficio. L'obiettivo e' avere uno strumento rapido per:

- gestire i giocatori disponibili;
- segnare chi e' presente in ufficio;
- comporre squadre 2 vs 2;
- registrare il punteggio di una partita;
- salvare lo storico dei risultati;
- consultare classifica e statistiche base.

Il tono dell'app e' volutamente interno e operativo: interfaccia dark, colori ispirati a NTT, navigazione semplice a tab e focus sull'uso quotidiano durante le pause.

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

La home usa una bottom navigation con quattro sezioni:

- **Giocatori**: elenco giocatori, stato presenza, aggiunta nuovo giocatore.
- **Partita**: composizione squadre, avvio partita, scoreboard, modifica punteggio, salvataggio risultato.
- **Storico**: registro partite con riepilogo, filtri, gruppi per data e card risultato.
- **Classifica**: ranking calcolato dalle partite salvate.

All'avvio `main.dart` carica `PlayerRepository` e `MatchRepository`, poi espone i repository tramite `MultiRepositoryProvider` e crea i Cubit globali principali.

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

I repository mantengono anche una cache in memoria e pubblicano stream broadcast. In questo modo piu' Cubit possono reagire agli stessi cambiamenti: ad esempio, salvare una partita aggiorna sia storico sia classifica senza far comunicare direttamente le schermate tra loro.

### Bloc/Cubit

La gestione stato e' stata spostata su Cubit per separare intenzioni utente, stato derivato e UI. Questa scelta rende il progetto piu' ordinato rispetto a tenere tutta la logica dentro widget stateful.

Esempi:

- `NewMatchCubit` gestisce composizione squadre, punteggio, validazione e salvataggio.
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
- Indicazione se ci sono almeno 4 presenti per giocare.
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
- Material 3.
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

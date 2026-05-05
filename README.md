# PuzzleGame

Prototipo di puzzle game **3x3** in **SwiftUI**, sviluppato come test tecnico per Funambol: l'immagine viene scaricata da Picsum (https://picsum.photos/) con fallback su asset locale, le tessere si scambiano via drag & drop, si bloccano quando arrivano in posizione corretta e l'utente viene notificato a puzzle completato.

> Solo framework Apple — nessuna dipendenza esterna.

---

## Come eseguire l'app da terminale (script `run.sh`)

Lo script `run.sh` automatizza build, install e launch su simulatore senza aprire Xcode.

#### Avvio tramite script

```bash
chmod +x run.sh (una volta sola)
./run.sh --list
./run.sh "iPhone 17 Pro"
```
#### Comandi disponibili

```bash
./run.sh                          # build + run su iPhone 15 (default)
./run.sh "iPhone 15 Pro"          # build + run su simulatore specifico
./run.sh "iPad Pro (12.9-inch) (6th generation)"   # anche iPad
./run.sh --list                   # mostra l'elenco dei simulatori installati
./run.sh --clean                  # clean build, poi run
./run.sh --clean "iPhone 15 Pro"  # clean + run su simulatore specifico
./run.sh --help                   # mostra l'header con tutti i comandi
```

## Demo

| Caricamento | Gameplay | Completamento |
| :---: | :---: | :---: |
| immagine random da Picsum | drag & drop, lock automatico | overlay di vittoria + restart |

Reference video: zefiro.me/share/JSYkL76rnRQper1P (https://zefiro.me/share/JSYkL76rnRQper1P)

---

## Caratteristiche

- ✅ Griglia **3x3** con tessere quadrate
- ✅ Immagine sorgente da `https://picsum.photos/1024`
- ✅ Fallback su asset locale se la rete non è disponibile
- ✅ **Drag & drop** per scambiare due tessere
- ✅ Tessere **lockate** una volta in posizione corretta (bordo verde)
- ✅ Notifica di **completamento** del puzzle con possibilità di riavviare
- ✅ **Sopravvive al cambio di orientamento** (portrait ↔ landscape)

---

## Architettura

Il progetto adotta un pattern **MVC** adattato all'idiomatica SwiftUI:

```
PuzzleGame/
├── PuzzleGameApp.swift          # entry point
├── Model/
│   └── Tile.swift               # value-type, stato di una tessera
├── Controller/
│   ├── PuzzleController.swift   # ObservableObject, logica di gioco
│   └── ImageLoader.swift        # rete + fallback, dietro protocollo
└── View/
    ├── ContentView.swift        # root view, gestione stati (loading/error/game)
    ├── PuzzleGridView.swift     # griglia + drag gesture
    ├── TileView.swift           # singola tessera
    └── CompletionOverlay.swift  # overlay di vittoria

```

| Ruolo MVC | Implementazione SwiftUI |
| --- | --- |
| **Model** | `struct Tile` — value type con `id`, `originalIndex`, `currentIndex`, `image`, `isLocked` (computed) |
| **Controller** | `PuzzleController: ObservableObject` `@MainActor` — espone `tiles`, `isCompleted`, `isLoading`, `errorMessage` come `@Published`. `ImageLoader` iniettato dietro protocollo `ImageLoading` |
| **View** | `ContentView` osserva il controller via `@StateObject`, le sotto-view via `@ObservedObject`. Le View contengono solo presentazione e gesture, nessuna logica |

## Requisiti

- **macOS** 13+ (Ventura o successivo consigliato)
- **Xcode** 15 o 16
- **iOS Simulator** 16+ (incluso in Xcode)

## Struttura repository

```
.
├── PuzzleGame.xcodeproj
├── PuzzleGame/
│   ├── PuzzleGameApp.swift
│   ├── Model/Tile.swift
│   ├── Controller/
│   │   ├── PuzzleController.swift
│   │   └── ImageLoader.swift
│   ├── View/
│   │   ├── ContentView.swift
│   │   ├── PuzzleGridView.swift
│   │   ├── TileView.swift
│   │   └── CompletionOverlay.swift
│   └── Assets.xcassets/
├── run.sh                # script build + run su simulatore
├── .gitignore
└── README.md
```

---

## .gitignore

Crea un `.gitignore` nella root con almeno:

```gitignore
# Build artifacts
build/
DerivedData/

# Xcode user data
xcuserdata/
*.xcworkspace/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/

# macOS
.DS_Store

```

---

## Licenza

MIT — vedi [LICENSE](./LICENSE).

---

## Autore

Guglielmo Chimera (https://github.com/gchimera) (www.chimeradev.it)

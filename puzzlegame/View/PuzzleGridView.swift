//
//  PuzzleGridView.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import SwiftUI

struct PuzzleGridView: View {
    @ObservedObject var controller: PuzzleController

    /// Id della tessera attualmente in drag (nil se nessuna).
    @State private var draggingTileId: Int? = nil
    /// Offset corrente del drag, applicato visivamente alla tessera.
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        // GeometryReader ci dà la dimensione disponibile, così la griglia
        // si adatta a portrait, landscape, iPad, ecc.
        GeometryReader { geo in
            // Lato della griglia = il minore tra larghezza e altezza disponibili.
            let side = min(geo.size.width, geo.size.height)
            let tileSide = side / CGFloat(controller.gridSize)

            ZStack(alignment: .topLeading) {
                // Sfondo: cornice della griglia.
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: side, height: side)

                // Disegniamo le tessere posizionandole tramite `.position`,
                // che usa il centro. Comodo per fare il pick "che slot è
                // sotto il dito?" con una semplice divisione.
                ForEach(controller.tiles) { tile in
                    let row = tile.currentIndex / controller.gridSize
                    let col = tile.currentIndex % controller.gridSize
                    let isDragging = (draggingTileId == tile.id)

                    TileView(tile: tile, side: tileSide)
                        .position(
                            x: CGFloat(col) * tileSide + tileSide / 2,
                            y: CGFloat(row) * tileSide + tileSide / 2
                        )
                        // Solo la tessera in drag si sposta; le altre restano ferme.
                        .offset(isDragging ? dragOffset : .zero)
                        // La tessera trascinata sta sopra le altre.
                        .zIndex(isDragging ? 1 : 0)
                        .gesture(makeDragGesture(for: tile, tileSide: tileSide))
                        // Animiamo solo i cambi di slot (non il drag in tempo reale).
                        .animation(.easeInOut(duration: 0.25),
                                   value: tile.currentIndex)
                }
            }
            .frame(width: side, height: side)
            // Centra la griglia nello spazio disponibile.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Drag gesture

    /// Costruisce il `DragGesture` per una specifica tessera.
    /// Il coordinate space è quello locale del ZStack (origine in alto-sx),
    /// quindi `value.location` è già nelle coordinate della griglia.
    private func makeDragGesture(for tile: Tile, tileSide: CGFloat) -> some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                // Le tessere lockate non si muovono nemmeno visualmente.
                guard !tile.isLocked else { return }
                draggingTileId = tile.id
                dragOffset = value.translation
            }
            .onEnded { value in
                // Reset visuale a fine gesto, qualunque sia l'esito.
                defer {
                    draggingTileId = nil
                    dragOffset = .zero
                }
                guard !tile.isLocked else { return }

                // Calcoliamo lo slot di destinazione dal punto in cui l'utente
                // ha rilasciato il dito. Divisione semplice → niente preference key.
                guard let targetSlot = slotIndex(at: value.location,
                                                 tileSide: tileSide) else {
                    return
                }
                // Deleghiamo lo swap al controller. Se le regole non sono
                // rispettate (lockata, stessa posizione...) ritorna false e basta.
                _ = controller.swap(from: tile.currentIndex, to: targetSlot)
            }
    }

    /// Converte un punto (in coord. locali della griglia) nell'indice di slot
    /// `0..<gridSize*gridSize`. Ritorna nil se il punto è fuori dalla griglia.
    private func slotIndex(at point: CGPoint, tileSide: CGFloat) -> Int? {
        guard tileSide > 0 else { return nil }
        let col = Int(point.x / tileSide)
        let row = Int(point.y / tileSide)
        guard (0..<controller.gridSize).contains(col),
              (0..<controller.gridSize).contains(row) else {
            return nil
        }
        return row * controller.gridSize + col
    }
}

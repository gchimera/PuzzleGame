//
//  PuzzleController.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import SwiftUI
import Combine

@MainActor
final class PuzzleController: ObservableObject {

    let gridSize: Int // dimensioni griglia

    var tileCount: Int { gridSize * gridSize } // numero totale delle tile

    @Published private(set) var tiles: [Tile] = []

    @Published private(set) var isCompleted: Bool = false

    @Published private(set) var isLoading: Bool = false

    @Published var errorMessage: String?

    private let imageLoader: ImageLoading

    init(gridSize: Int = 3, imageLoader: ImageLoading = ImageLoader()) {
        self.gridSize = gridSize
        self.imageLoader = imageLoader
    }

    func loadPuzzle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let image = await imageLoader.loadImage() else {
            errorMessage = "Impossibile caricare l'immagine."
            return
        }

        let pieces = splitImage(image, into: gridSize)
        guard pieces.count == tileCount else {
            errorMessage = "Errore nello split dell'immagine."
            return
        }

        var newTiles = pieces.enumerated().map { index, img in
            Tile(id: index, originalIndex: index, currentIndex: index, image: img)
        }

        shuffle(&newTiles)
        self.tiles = newTiles
        self.isCompleted = false
    }

    
    @discardableResult
    func swap(from: Int, to: Int) -> Bool {
        guard from != to else { return false }

        // Cerchiamo le tessere per currentIndex (l'ordine in tiles[] è arbitrario).
        guard let fromIdx = tiles.firstIndex(where: { $0.currentIndex == from }),
              let toIdx   = tiles.firstIndex(where: { $0.currentIndex == to }) else {
            return false
        }

        // Regola: tessere lockate non si muovono. Vale per entrambe.
        if tiles[fromIdx].isLocked || tiles[toIdx].isLocked {
            return false
        }

        // Scambio gli indici di posizione corrente.
        tiles[fromIdx].currentIndex = to
        tiles[toIdx].currentIndex   = from

        checkCompletion()
        return true
    }

    private func checkCompletion() {
        isCompleted = tiles.allSatisfy { $0.currentIndex == $0.originalIndex }
    }

    func splitImage(_ image: UIImage, into n: Int) -> [UIImage] {
        guard let cgImage = image.cgImage else { return [] }

        let width  = cgImage.width
        let height = cgImage.height
        // Usiamo la divisione intera: eventuali pixel residui vengono troncati,
        // così tutte le tessere hanno esattamente la stessa dimensione.
        let tileW = width  / n
        let tileH = height / n

        var pieces: [UIImage] = []
        pieces.reserveCapacity(n * n)

        for row in 0..<n {
            for col in 0..<n {
                let rect = CGRect(x: col * tileW,
                                  y: row * tileH,
                                  width: tileW,
                                  height: tileH)
                if let cropped = cgImage.cropping(to: rect) {
                    pieces.append(UIImage(cgImage: cropped,
                                          scale: image.scale,
                                          orientation: image.imageOrientation))
                }
            }
        }
        return pieces
    }

    private func shuffle(_ tiles: inout [Tile]) {
        let n = tiles.count
        var positions = Array(0..<n)
        repeat {
            positions.shuffle()
        } while positions == Array(0..<n)   // evita identità

        for i in 0..<n {
            tiles[i].currentIndex = positions[i]
        }
    }
}

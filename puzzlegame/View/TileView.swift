//
//  TileView.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import SwiftUI

/// Vista di una singola tessera. Pura presentazione, nessuna logica.
struct TileView: View {
    let tile: Tile
    let side: CGFloat

    var body: some View {
        Image(uiImage: tile.image)
            .resizable()
            .frame(width: side, height: side)
            // bordo verde in posizione finale altrimenti bianco semi-trasparente.
            .overlay(
                Rectangle()
                    .stroke(tile.isLocked ? Color.green : Color.white.opacity(0.25),
                            lineWidth: tile.isLocked ? 2 : 1)
            )
            // applico effetto trasparente se una tessera si trova in posione finale.
            .opacity(tile.isLocked ? 0.95 : 1.0)
    }
}

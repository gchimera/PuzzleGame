//
//  CompletionOverlay.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import SwiftUI

/// Overlay full-screen mostrato quando il puzzle è completato.
struct CompletionOverlay: View {
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            // Velo scuro semi-trasparente.
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))
                Text("Puzzle Completato!")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Button(action: onRestart) {
                    Text("Nuova Partita")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
}

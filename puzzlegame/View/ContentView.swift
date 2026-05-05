//
//  ContentView.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var controller = PuzzleController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Stato 1: caricamento
            if controller.isLoading {
                ProgressView("Caricamento immagine...")
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .foregroundColor(.white)
            }
            // Stato 2: errore
            else if let msg = controller.errorMessage {
                VStack(spacing: 16) {
                    Text(msg)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Button("Riprova") {
                        Task { await controller.loadPuzzle() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            // Stato 3: gioco
            else if !controller.tiles.isEmpty {
                PuzzleGridView(controller: controller)
                    .padding()
            }

            // Overlay di vittoria sopra tutto.
            if controller.isCompleted {
                CompletionOverlay {
                    Task { await controller.loadPuzzle() }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: controller.isCompleted)
        // .task viene eseguito al primo apparire della view.
        // Non riparte alla rotazione → l'immagine si carica una sola volta.
        .task {
            if controller.tiles.isEmpty {
                await controller.loadPuzzle()
            }
        }
    }
}

#Preview {
    ContentView()
}

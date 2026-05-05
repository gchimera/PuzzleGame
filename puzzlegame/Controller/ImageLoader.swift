//
//  ImageLoader.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import UIKit

protocol ImageLoading {
    func loadImage() async -> UIImage?
}

final class ImageLoader: ImageLoading {

    private let remoteURL = URL(string: "https://picsum.photos/1024")!
    private let fallbackAssetName = "puzzle_fallback"
    private let timeout: TimeInterval = 10

    // se il download fallisce uso l'immagine locale
    func loadImage() async -> UIImage? {
        if let remote = await fetchRemote() {
            return remote
        }
        return UIImage(named: fallbackAssetName)
    }

    private func fetchRemote() async -> UIImage? {
        do {
            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = timeout
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                return nil
            }
            return UIImage(data: data)
        } catch {
            print("Errore: \(error)") ;
            return nil
        }
    }
}

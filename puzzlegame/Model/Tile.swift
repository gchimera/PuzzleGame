//
//  Tile.swift
//  puzzlegame
//
//  Created by Guglielmo Chimera on 05/05/2026.
//

import SwiftUI

struct Tile: Identifiable, Equatable {

    let id: Int

    let originalIndex: Int // posizione corretta del tile

    var currentIndex: Int // posizione corrente del tile. Cambia a ogni gesture

    let image: UIImage

    var isLocked: Bool {
        currentIndex == originalIndex // blocco il tile se la posizione corrente coincide con la posizione corretta
    }
}

//
//  OthelloViewModel.swift
//  Othello
//
//  Created by Petteri Kamppuri on 29.7.2018.
//  Copyright © 2018 Petteri Kamppuri. All rights reserved.
//

import UIKit

struct OthelloViewModel {
    let board: OthelloBoard
    let whiteScoreText: String
    let blackScoreText: String
    let turnText: String
    let isTurnTextVisible: Bool
    let winningText: String
    let isWinningTextVisible: Bool
    let highlightedSquares: [OthelloMove]
    let highlightedMoves: [(move: OthelloMove, color: UIColor)]
    let aiInfo: String
}

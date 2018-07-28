//
//  MCTSNode.swift
//  Othello
//
//  Created by Petteri Kamppuri on 28.7.2018.
//  Copyright © 2018 Petteri Kamppuri. All rights reserved.
//

import Foundation


final class MCTSNode {
    let gameState: OthelloGame
    weak var parent: MCTSNode?
    var children: [MCTSNode]
    var wins: Int
    var plays: Int
    var move: OthelloMove // Move that was made to make the state in this node
    var allMovesExpanded: Bool
    
    convenience init(gameState: OthelloGame) {
        self.init(gameState: gameState, move: OthelloMove(x: -1, y: -1))
    }
    
    init(gameState: OthelloGame, move: OthelloMove) {
        self.gameState = gameState
        self.move = move
        self.children = []
        self.wins = 0
        self.plays = 0
        self.allMovesExpanded = false
    }
    
    func hasVisitedMove(_ move: OthelloMove) -> Bool {
        for child in self.children {
            if child.move == move {
                return true
            }
        }
        return false
    }
    
    func addChild(_ child: MCTSNode) {
        child.parent = self
        self.children.append(child)
    }
    
    func hasUnsimulatedPlays() -> Bool {
        if case .tie = self.gameState.state {
            return false
        }
        if case .won(_) = self.gameState.state {
            return false
        }
        
        if self.allMovesExpanded == false {
            return true
        }
        
        if self.children.count == 0 {
            return true
        }
        
        for child in self.children {
            if child.hasUnsimulatedPlays() {
                return true
            }
        }
        
        return false
    }
}

extension MCTSNode : Equatable {}

func ==(lhs: MCTSNode, rhs: MCTSNode) -> Bool {
    return lhs.gameState == rhs.gameState //&& lhs.move == rhs.move
}

extension MCTSNode : Hashable {
    var hashValue: Int {
        return gameState.hashValue
    }
}




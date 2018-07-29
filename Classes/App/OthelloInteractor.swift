//
//  OthelloInteractor.swift
//  Othello
//
//  Created by Petteri Kamppuri on 29.7.2018.
//  Copyright © 2018 Petteri Kamppuri. All rights reserved.
//

import UIKit

protocol OthelloInteractorListener: AnyObject {
    func didUpdate(viewModel: OthelloViewModel)
}

class OthelloInteractor {
    private var game: OthelloGame!
    private let playerColor = OthelloBoard.Color.white
    private let aiColor = OthelloBoard.Color.black
    private var mctsSearch: MonteCarloTreeSearch!
    private var aiInfo: String = ""
    private var highlightedMoves: [(move: OthelloMove, color: UIColor)] = []
    
    init() {
        self.game = OthelloGame()
    }
    
    var showTips: Bool = false { didSet {
        self.notifyViewModelDidChange()
        }
    }
    
    var listener: OthelloInteractorListener? {
        didSet {
            self.notifyViewModelDidChange()
        }
    }
    
    func makePlayerMove(_ move: OthelloMove) {
        if case .turn(let color) = self.game.state , color != self.playerColor {
            return
        }
        
        if case .turn(let color) = self.game.state {
            if self.game.isValidMove(move, forColor: color) {
                self.game.makeMove(move, forColor: color)
                notifyViewModelDidChange()
                
                checkAI()
            }
        }
    }
}

private extension OthelloInteractor {
    private func checkAI() {
        if case .turn(let color) = self.game.state , color == self.aiColor {
            let currentGameState = self.game
            
            if self.mctsSearch == nil {
                self.mctsSearch = MonteCarloTreeSearch(startingGameState: currentGameState!, aiColor: self.aiColor)
            }
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                self.runAI(timeLimit: 2.0, fromGameState: currentGameState!)
            }
        }
    }
    
    private func runAI(timeLimit: TimeInterval, fromGameState currentGameState: OthelloGame) {
        print("Starting Monte Carlo Tree Search")
        
        self.mctsSearch.updateStartingState(currentGameState) // Use this to reuse already computed nodes
        //self.mctsSearch = MonteCarloTreeSearch(startingGameState: currentGameState, aiColor: self.aiColor) // Use this to start with a clean sheet.
        
        // Loop until allotted timeLimit is reached,
        // eport updates to ui frequently so the user doesn't have to start an static screen
        let uiUpdateInterval = 0.1
        let start = Date.timeIntervalSinceReferenceDate
        var lastUpdateTime = start
        while Date.timeIntervalSinceReferenceDate - start < timeLimit {
            if self.mctsSearch.hasUnsimulatedPlays() == false {
                break
            }
            
            self.mctsSearch.iterateSearch()
            
            let now = Date.timeIntervalSinceReferenceDate
            if now - lastUpdateTime > uiUpdateInterval {
                lastUpdateTime = now
                let tempSearchResults = self.mctsSearch.results()
                
                DispatchQueue.main.async {
                    self.updateAIWithInterimSearchResults(tempSearchResults)
                }
            }
        }
        let end = Date.timeIntervalSinceReferenceDate
        
        let searchResults = self.mctsSearch.results()
        
        self.printResults(searchResults)
        
        let bestMove = searchResults.bestMove
        print("    Simulated \(searchResults.simulations) games, conf: \(Int(searchResults.confidence * 100))%")
        print("    Chose move \(bestMove)")
        
        DispatchQueue.main.async {
            self.makeAIMove(bestMove, searchResults: searchResults, duration: end - start)
        }
    }
    
    private func updateAIWithInterimSearchResults(_ searchResults: (bestMove: OthelloMove, simulations: Int, confidence: Double, moves: [MCTSNode])) {
        self.aiInfo = "Simulated \(searchResults.simulations) games"
        
        var highlightedMoves = [(move: OthelloMove, color: UIColor)]()
        for moveNode in searchResults.moves {
            let winrate = CGFloat(moveNode.wins) / CGFloat(moveNode.plays)
            highlightedMoves.append((move: moveNode.move, color: UIColor(white: 0.2, alpha: winrate)))
        }
        
        self.highlightedMoves = highlightedMoves
        
        self.notifyViewModelDidChange()
    }
    
    private func makeAIMove(_ move: OthelloMove, searchResults: (bestMove: OthelloMove, simulations: Int, confidence: Double, moves: [MCTSNode]), duration: TimeInterval) {
        self.game.makeMove(move, forColor: self.aiColor)
        
        self.highlightedMoves = []
        
        self.aiInfo = "Simulated \(searchResults.simulations) games in \(Int(duration)) s, conf: \(Int(searchResults.confidence * 100))%"
        
        self.notifyViewModelDidChange()
        
        self.checkAI()
    }
    
    private func printResults(_ searchResults: (bestMove: OthelloMove, simulations: Int, confidence: Double, moves: [MCTSNode])) {
        for moveNove in searchResults.moves.sorted(by: { (left: MCTSNode, right: MCTSNode) -> Bool in
            return Double(left.wins) / Double(left.plays) > Double(right.wins) / Double(right.plays)
        }) {
            if moveNove.plays > 0 {
                let winrate = Double(moveNove.wins) / Double(moveNove.plays)
                print("    Move \(moveNove.move): win confidence: \(Int(winrate * 100))%, \(moveNove.plays) plays")
            }
        }
    }
    
    static private func viewModel(for game: OthelloGame,
                                  showTips: Bool,
                                  aiInfo: String,
                                  highlightedMoves: [(move: OthelloMove, color: UIColor)]) -> OthelloViewModel {
        let board = game.board
        
        let whiteScoreText = "White: \(game.board.numberOfWhitePieces())"
        let blackScoreText = "Black: \(game.board.numberOfBlackPieces())"
        
        let turnText: String
        let isTurnTextVisible: Bool
        let winningText: String
        let isWinningTextVisible: Bool
        let highlightedSquares: [OthelloMove]
        
        switch game.state {
        case .turn(let color):
            turnText = "\(color) turn"
            isTurnTextVisible = true
            winningText = ""
            isWinningTextVisible = false
            if showTips {
                highlightedSquares = game.allMoves(color)
            } else {
                highlightedSquares = []
            }
        case .tie:
            turnText = ""
            isTurnTextVisible = false
            isWinningTextVisible = true
            winningText = "Game over: tied"
            highlightedSquares = []
        case .won(let color):
            turnText = ""
            isTurnTextVisible = false
            isWinningTextVisible = true
            winningText = "\(color) won!"
            highlightedSquares = []
        }
        
        return OthelloViewModel(board: board,
                                whiteScoreText: whiteScoreText,
                                blackScoreText: blackScoreText,
                                turnText: turnText,
                                isTurnTextVisible: isTurnTextVisible,
                                winningText: winningText,
                                isWinningTextVisible: isWinningTextVisible,
                                highlightedSquares: highlightedSquares,
                                highlightedMoves: highlightedMoves,
                                aiInfo: aiInfo)
    }
}

private extension OthelloInteractor {
    func notifyViewModelDidChange() {
        guard let listener = self.listener else { return }
        
        let viewModel = OthelloInteractor.viewModel(for: self.game,
                                                    showTips: self.showTips,
                                                    aiInfo: self.aiInfo,
                                                    highlightedMoves: self.highlightedMoves)
        
        listener.didUpdate(viewModel: viewModel)
    }
}

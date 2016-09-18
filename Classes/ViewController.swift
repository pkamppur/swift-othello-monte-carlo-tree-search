//
//  ViewController.swift
//  Othello
//
//  Created by Petteri Kamppuri on 25.3.2016.
//  Copyright © 2016 Petteri Kamppuri. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var othelloView: OthelloView!
	@IBOutlet weak var whiteScoreLabel: UILabel!
	@IBOutlet weak var blackScoreLabel: UILabel!
	@IBOutlet weak var turnTextLabel: UILabel!
	@IBOutlet weak var winningTextLabel: UILabel!
	@IBOutlet weak var boardMarginConstraint: NSLayoutConstraint!
	@IBOutlet weak var aiInfoLabel: UILabel!
	
	fileprivate var game: OthelloGame!
	fileprivate let playerColor = OthelloBoard.Color.white
	fileprivate let aiColor = OthelloBoard.Color.black
	fileprivate var mctsSearch: MonteCarloTreeSearch!
	fileprivate var showTips: Bool = false { didSet {
		self.updateUI()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.game = OthelloGame()
		self.aiInfoLabel.text = ""
		
		updateUI()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateBoardMargin(self.view.bounds.size)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		updateBoardMargin(size)
	}
	
	fileprivate func updateBoardMargin(_ size: CGSize) {
		self.boardMarginConstraint.constant = floor(size.width * 0.025)
	}
	
	@IBAction func boardTapped(_ tapRecognizer: UITapGestureRecognizer) {
		if case .turn(let color) = self.game.state , color != self.playerColor {
			return
		}
		
		let move = othelloView.moveFromPoint(tapRecognizer.location(in: othelloView))
		
		if case .turn(let color) = self.game.state {
			if self.game.isValidMove(move, forColor: color) {
				self.game.makeMove(move, forColor: color)
				updateUI()
				
				checkAI()
			}
		}
	}
	
	@IBAction func toggleShowTips(_ sender: AnyObject) {
		self.showTips = !self.showTips
	}
	
	fileprivate func checkAI() {
		if case .turn(let color) = self.game.state , color == self.aiColor {
			let currentGameState = self.game
			
			if self.mctsSearch == nil {
				self.mctsSearch = MonteCarloTreeSearch(startingGameState: currentGameState!, aiColor: self.aiColor)
			}
			
			DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: {
				self.runAI(timeLimit: 2.0, fromGameState: currentGameState!)
			})
		}
	}
	
	fileprivate func runAI(timeLimit: TimeInterval, fromGameState currentGameState: OthelloGame) {
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
				
				DispatchQueue.main.async(execute: {
					self.updateAIWithInterimSearchResults(tempSearchResults)
				})
			}
		}
		let end = Date.timeIntervalSinceReferenceDate
		
		let searchResults = self.mctsSearch.results()
		
		self.printResults(searchResults)
		
		let bestMove = searchResults.bestMove
		print("    Simulated \(searchResults.simulations) games, conf: \(Int(searchResults.confidence * 100))%")
		print("    Chose move \(bestMove)")
		
		DispatchQueue.main.async(execute: {
			self.makeAIMove(bestMove, searchResults: searchResults, duration: end - start)
		})
	}
	
	fileprivate func updateAIWithInterimSearchResults(_ searchResults: (bestMove: OthelloMove, simulations: Int, confidence: Double, moves: [MCTSNode])) {
		self.aiInfoLabel.text = "Simulated \(searchResults.simulations) games"
		
		var highlightedMoves = [(move: OthelloMove, color: UIColor)]()
		for moveNode in searchResults.moves {
			let winrate = CGFloat(moveNode.wins) / CGFloat(moveNode.plays)
			highlightedMoves.append((move: moveNode.move, color: UIColor(white: 0.2, alpha: winrate)))
		}
		
		self.othelloView.highlightedMoves = highlightedMoves
	}
	
	fileprivate func makeAIMove(_ move: OthelloMove, searchResults: (bestMove: OthelloMove, simulations: Int, confidence: Double, moves: [MCTSNode]), duration: TimeInterval) {
		self.game.makeMove(move, forColor: self.aiColor)
		
		self.othelloView.highlightedMoves = []
		
		self.aiInfoLabel.text = "Simulated \(searchResults.simulations) games in \(Int(duration)) s, conf: \(Int(searchResults.confidence * 100))%"
		
		self.updateUI()
		
		self.checkAI()
	}
	
	fileprivate func printResults(_ searchResults: (bestMove: OthelloMove, simulations: Int, confidence: Double, moves: [MCTSNode])) {
		for moveNove in searchResults.moves.sorted(by: { (left: MCTSNode, right: MCTSNode) -> Bool in
			return Double(left.wins) / Double(left.plays) > Double(right.wins) / Double(right.plays)
		}) {
			if moveNove.plays > 0 {
				let winrate = Double(moveNove.wins) / Double(moveNove.plays)
				print("    Move \(moveNove.move): win confidence: \(Int(winrate * 100))%, \(moveNove.plays) plays")
			}
		}
	}
	
	fileprivate func updateUI() {
		self.othelloView.board = self.game.board
		
		self.whiteScoreLabel.text = "White: \(self.game.board.numberOfWhitePieces())"
		self.blackScoreLabel.text = "Black: \(self.game.board.numberOfBlackPieces())"
		
		switch self.game.state {
		case .turn(let color):
			self.turnTextLabel.text = "\(color) turn"
			self.turnTextLabel.isHidden = false
			self.winningTextLabel.isHidden = true
			if self.showTips {
				self.othelloView.highlightedSquares = self.game.allMoves(color)
			} else {
				self.othelloView.highlightedSquares = []
			}
		case .tie:
			self.turnTextLabel.isHidden = true
			self.winningTextLabel.isHidden = false
			self.winningTextLabel.text = "Game over: tied"
		case .won(let color):
			self.turnTextLabel.isHidden = true
			self.winningTextLabel.isHidden = false
			self.winningTextLabel.text = "\(color) won!"
		}
	}
}


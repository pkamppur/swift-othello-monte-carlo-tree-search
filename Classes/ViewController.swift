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
	
	private var game: OthelloGame!
	private let playerColor = OthelloBoard.Color.White
	private let aiColor = OthelloBoard.Color.Black
	private var mctsSearch: MonteCarloTreeSearch!
	private var showTips: Bool = false { didSet {
		self.updateUI()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.game = OthelloGame()
		self.aiInfoLabel.text = ""
		
		updateUI()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		updateBoardMargin(self.view.bounds.size)
	}
	
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		updateBoardMargin(size)
	}
	
	private func updateBoardMargin(size: CGSize) {
		self.boardMarginConstraint.constant = floor(size.width * 0.025)
	}
	
	@IBAction func boardTapped(tapRecognizer: UITapGestureRecognizer) {
		if case .Turn(let color) = self.game.state where color != self.playerColor {
			return
		}
		
		let move = othelloView.moveFromPoint(tapRecognizer.locationInView(othelloView))
		
		if case .Turn(let color) = self.game.state {
			if self.game.isValidMove(move, forColor: color) {
				self.game.makeMove(move, forColor: color)
				updateUI()
				
				checkAI()
			}
		}
	}
	
	@IBAction func toggleShowTips(sender: AnyObject) {
		self.showTips = !self.showTips
	}
	
	private func checkAI() {
		if case .Turn(let color) = self.game.state where color == self.aiColor {
			let currentGameState = self.game
			
			if self.mctsSearch == nil {
				self.mctsSearch = MonteCarloTreeSearch(startingGameState: currentGameState, aiColor: self.aiColor)
			}
			
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), {
				let timeLimit = 2.0
				let uiUpdateInterval = 0.1
				
				print("Starting Monte Carlo Tree Search")
				
				self.mctsSearch.updateStartingState(currentGameState) // Use this to reuse already computed nodes
				//self.mctsSearch = MonteCarloTreeSearch(startingGameState: currentGameState, aiColor: self.aiColor) // Use this to start with a clean sheet.
				
				let start = NSDate.timeIntervalSinceReferenceDate()
				while NSDate.timeIntervalSinceReferenceDate() - start < timeLimit {
					if self.mctsSearch.hasUnsimulatedPlays() == false {
						break
					}
					
					let iterationsStart = NSDate.timeIntervalSinceReferenceDate()
					while NSDate.timeIntervalSinceReferenceDate() - iterationsStart < uiUpdateInterval {
						self.mctsSearch.iterateSearch()
					}
					
					let tempSearchResults = self.mctsSearch.results()
					
					dispatch_async(dispatch_get_main_queue(), {
						self.aiInfoLabel.text = "Simulated \(tempSearchResults.simulations) games"
						
						var highlightedMoves = [(move: OthelloMove, color: UIColor)]()
						for moveNode in tempSearchResults.moves {
							let winrate = CGFloat(moveNode.wins) / CGFloat(moveNode.plays)
							highlightedMoves.append((move: moveNode.move, color: UIColor(white: 0.2, alpha: winrate)))
						}
						
						self.othelloView.highlightedMoves = highlightedMoves
					})
				}
				let end = NSDate.timeIntervalSinceReferenceDate()
				
				let searchResults = self.mctsSearch.results()
				
				for moveNove in searchResults.moves.sort({ (left: MCTSNode, right: MCTSNode) -> Bool in
					return Double(left.wins) / Double(left.plays) > Double(right.wins) / Double(right.plays)
				}) {
					if moveNove.plays > 0 {
						let winrate = Double(moveNove.wins) / Double(moveNove.plays)
						print("    Move \(moveNove.move): win confidence: \(Int(winrate * 100))%, \(moveNove.plays) plays")
					}
				}
				
				let move = searchResults.bestMove
				print("    Simulated \(searchResults.simulations) games, conf: \(Int(searchResults.confidence * 100))%")
				
				print("    Chose move \(move)")
				
				dispatch_async(dispatch_get_main_queue(), { 
					self.game.makeMove(move, forColor: color)
					
					self.othelloView.highlightedMoves = []
					
					self.aiInfoLabel.text = "Simulated \(searchResults.simulations) games in \(Int(end - start)) s, conf: \(Int(searchResults.confidence * 100))%"
					
					self.updateUI()
					
					self.checkAI()
				})
			})
		}
	}
	
	private func updateUI() {
		self.othelloView.board = self.game.board
		
		self.whiteScoreLabel.text = "White: \(self.game.board.numberOfWhitePieces())"
		self.blackScoreLabel.text = "Black: \(self.game.board.numberOfBlackPieces())"
		
		switch self.game.state {
		case .Turn(let color):
			self.turnTextLabel.text = "\(color) turn"
			self.turnTextLabel.hidden = false
			self.winningTextLabel.hidden = true
			if self.showTips {
				self.othelloView.highlightedSquares = self.game.allMoves(color)
			} else {
				self.othelloView.highlightedSquares = []
			}
		case .Tie:
			self.turnTextLabel.hidden = true
			self.winningTextLabel.hidden = false
			self.winningTextLabel.text = "Game over: tied"
		case .Won(let color):
			self.turnTextLabel.hidden = true
			self.winningTextLabel.hidden = false
			self.winningTextLabel.text = "\(color) won!"
		}
	}
}


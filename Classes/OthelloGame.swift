//
//  OthelloGame.swift
//  Othello
//
//  Created by Petteri Kamppuri on 26.3.2016.
//  Copyright © 2016 Petteri Kamppuri. All rights reserved.
//

import Foundation

struct OthelloMove {
	var x: Int
	var y: Int
}

extension OthelloMove : Equatable {}

func ==(lhs: OthelloMove, rhs: OthelloMove) -> Bool {
	return lhs.x == rhs.x && lhs.y == rhs.y
}

extension OthelloMove : Hashable {
	var hashValue: Int {
		return (self.x) | (self.y << 16)
	}
}


struct OthelloGame {
	enum State {
		case Turn(OthelloBoard.Color)
		case Won(OthelloBoard.Color)
		case Tie
	}
	
	private(set) var board: OthelloBoard
	private(set) var state: State
	
	init () {
		self.board = OthelloBoard()
		self.board[3, 3] = OthelloBoard.Piece.Color(OthelloBoard.Color.White)
		self.board[4, 4] = OthelloBoard.Piece.Color(OthelloBoard.Color.White)
		self.board[3, 4] = OthelloBoard.Piece.Color(OthelloBoard.Color.Black)
		self.board[4, 3] = OthelloBoard.Piece.Color(OthelloBoard.Color.Black)
		
		self.state = .Turn(OthelloBoard.Color.White)
	}
	
	func allMoves(color: OthelloBoard.Color) -> [OthelloMove] {
		var moves: Array<OthelloMove> = []
		
		for x in 0..<self.board.boardWidth
		{
			for y in 0..<self.board.boardHeight
			{
				let move = OthelloMove(x: x, y: y)
				if isValidMove(move, forColor:color)
				{
					moves.append(move)
				}
			}
		}
		
		return moves
	}
	
	func currentColor() -> OthelloBoard.Color? {
		if case .Turn(let currentPlayerColor) = self.state {
			return currentPlayerColor
		} else {
			return nil
		}
	}
	
	func hasMoves(color: OthelloBoard.Color) -> Bool {
		for x in 0..<self.board.boardWidth
		{
			for y in 0..<self.board.boardHeight
			{
				let move = OthelloMove(x: x, y: y)
				if isValidMove(move, forColor:color)
				{
					return true
				}
			}
		}
		
		return false
	}
	
	func isTurnOf(color: OthelloBoard.Color) -> Bool {
		if case .Turn(let currentPlayerColor) = self.state where currentPlayerColor == color {
			return true
		} else {
			return false
		}
	}
	
	func isValidMove(move: OthelloMove, forColor color: OthelloBoard.Color) -> Bool {
		return processLinesForMove(move, forColor: color, lineProcessor: nil)
	}
	
	static func makeMove(startingState startingState: OthelloGame, move: OthelloMove, forColor color: OthelloBoard.Color) -> OthelloGame {
		if !startingState.isTurnOf(color) {
			return startingState
		}
		
		var newState = startingState
		
		newState.processLinesForMove(move, forColor: color) { (endX, endY, dx, dy) in
			var curX = endX
			var curY = endY
			while !(curX == move.x && curY == move.y)
			{
				curX -= dx
				curY -= dy
				
				newState.board[curX, curY] = .Color(color)
			}
		}
		
		let boardFull = newState.board.isFull
		
		if boardFull == false && newState.hasMoves(color.opposite()) {
			// Pass turn to the other player
			newState.state = .Turn(color.opposite())
		} else if boardFull == false && newState.hasMoves(color) {
			// Same player continues, because the other player doens't have moves
		} else {
			// Game has ended
			if newState.board.numberOfWhitePieces() > newState.board.numberOfBlackPieces() {
				newState.state = .Won(.White)
			} else if newState.board.numberOfWhitePieces() < newState.board.numberOfBlackPieces() {
				newState.state = .Won(.Black)
			} else {
				newState.state = .Tie
			}
		}
		
		return newState
	}
	
	mutating func makeMove(move: OthelloMove, forColor color: OthelloBoard.Color) {
		self = OthelloGame.makeMove(startingState: self, move: move, forColor: color)
	}
	
	static let xDirs = [ -1, -1, -1,  0,  1,  1,  1,  0 ]
	static let yDirs = [ -1,  0,  1,  1,  1,  0, -1, -1 ]
	
	func processLinesForMove(move: OthelloMove, forColor color: OthelloBoard.Color, lineProcessor: ((endX: Int, endY: Int, dx: Int, dy: Int) -> Void)?) -> Bool {
		if !self.board.isValidCoordinate(x: move.x, y: move.y) {
			return false
		}
		
		if !self.board.isEmptyAt(x: move.x, y: move.y) {
			return false
		}
		
		let opposite = color.opposite()
		
		var moveIsValid = false
		for dir in 0..<OthelloGame.xDirs.count
		{
			var tempX = move.x
			var tempY = move.y
			
			var hasFoundOpposite = false
			
			directionSearch: while true {
				tempX += OthelloGame.xDirs[dir]
				tempY += OthelloGame.yDirs[dir]
				
				if !self.board.isValidCoordinate(x: tempX, y: tempY) {
					break
				}
				
				let piece = self.board.pieceAt(x: tempX, y: tempY)
				
				switch piece {
				case .Color(let pieceColor):
					if pieceColor == color {
						if hasFoundOpposite {
							if lineProcessor != nil {
								moveIsValid = true
								lineProcessor!(endX: tempX, endY: tempY, dx: OthelloGame.xDirs[dir], dy: OthelloGame.yDirs[dir])
							} else {
								return true
							}
						}
						break directionSearch
					} else if pieceColor == opposite {
						hasFoundOpposite = true
					}
				case .Empty:
					break directionSearch
				}
			}
		}
		
		return moveIsValid
	}
}

extension OthelloGame.State : Equatable {}

func ==(lhs: OthelloGame.State, rhs: OthelloGame.State) -> Bool {
	switch (lhs, rhs) {
	case (.Turn(let lColor), .Turn(let rColor)) where lColor == rColor:
		return true
	case (.Won(let lColor), .Won(let rColor)) where lColor == rColor:
		return true
	case (.Tie, .Tie):
		return true
	default:
		return false
	}
}

extension OthelloGame : Equatable {}

func ==(lhs: OthelloGame, rhs: OthelloGame) -> Bool {
	return lhs.board == rhs.board && lhs.state == rhs.state
}

extension OthelloGame : Hashable {
	var hashValue: Int {
		return board.hashValue
	}
}

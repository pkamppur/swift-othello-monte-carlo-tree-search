//
//  OthelloView.swift
//  Othello
//
//  Created by Petteri Kamppuri on 26.3.2016.
//  Copyright © 2016 Petteri Kamppuri. All rights reserved.
//

import UIKit




class OthelloView: UIView {
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	var board: OthelloBoard? {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	var highlightedSquares: [OthelloMove] = [] {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	var highlightedMoves: [(move: OthelloMove, color: UIColor)] = [] {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	func moveFromPoint(point: CGPoint) -> OthelloMove {
		guard let board = self.board else {
			return OthelloMove(x: -1, y: -1)
		}
		
		let frameRect = self.bounds
		let blockWidth: Int = Int(frameRect.size.width - 1) / board.boardWidth
		let blockHeight: Int = Int(frameRect.size.height - 1) / board.boardHeight
		
		var x = Int(point.x) / blockWidth
		var y = Int(point.y) / blockHeight
		
		if x < 0 {
			x = 0
		}
		if x > board.boardWidth - 1 {
			x = board.boardWidth - 1
		}
		if y < 0 {
			y = 0
		}
		if y > board.boardHeight - 1 {
			y = board.boardHeight - 1
		}
		
		return OthelloMove(x: x, y: y)
	}
	
	override func drawRect(rect: CGRect) {
		guard let board = self.board else {
			return
		}
		
		let frameRect = self.bounds
		
		let blockWidth: Int = Int(frameRect.size.width - 1) / board.boardWidth;
		let blockHeight: Int = Int(frameRect.size.height - 1) / board.boardHeight;
		
		UIColor.whiteColor().set()
		UIRectFill(frameRect)
		
		UIColor.blackColor().set()
		
		let blockRectCalculator = { (x: Int, y: Int) -> CGRect in
			let blockRect = CGRect(x: x * blockWidth,
				y: y * blockHeight,
				width: blockWidth + 1,
				height: blockHeight + 1)
			return blockRect
		}
		
		board.iterateBoard { (x, y, piece) in
			let blockRect = blockRectCalculator(x, y)
			
			UIRectFrame(blockRect)
			
			let path = UIBezierPath(ovalInRect: blockRect.insetBy(dx: 2, dy: 2))
			
			switch piece {
			case .Color(let color):
				switch color {
				case .White:
					path.stroke()
					break
				case .Black:
					path.fill()
					break
				}
				break;
			case .Empty:
				break;
			}
			
			if self.highlightedSquares.contains(OthelloMove(x: x, y: y)) {
				UIColor.blueColor().set()
				UIRectFrame(blockRect.insetBy(dx: 1, dy: 1))
				UIColor.blackColor().set()
			}
		}
		
		for highlightedMove in highlightedMoves {
			highlightedMove.color.set()
			let blockRect = blockRectCalculator(highlightedMove.move.x, highlightedMove.move.y).insetBy(dx: 1, dy: 1)
			UIRectFillUsingBlendMode(blockRect, .Normal)
		}
	}
}

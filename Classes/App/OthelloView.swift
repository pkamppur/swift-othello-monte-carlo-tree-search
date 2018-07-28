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
    
    func moveFromPoint(_ point: CGPoint) -> OthelloMove {
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
}

// MARK: UIView overrides
extension OthelloView {
    override func draw(_ rect: CGRect) {
        guard let board = self.board else {
            return
        }
        
        let frameRect = self.bounds
        
        let blockWidth: Int = Int(frameRect.size.width - 1) / board.boardWidth;
        let blockHeight: Int = Int(frameRect.size.height - 1) / board.boardHeight;
        
        UIColor.white.set()
        UIRectFill(frameRect)
        
        UIColor.black.set()
        
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
            
            let path = UIBezierPath(ovalIn: blockRect.insetBy(dx: 2, dy: 2))
            
            switch piece {
            case .color(let color):
                switch color {
                case .white:
                    path.stroke()
                    break
                case .black:
                    path.fill()
                    break
                }
                break;
            case .empty:
                break;
            }
            
            if self.highlightedSquares.contains(OthelloMove(x: x, y: y)) {
                UIColor.blue.set()
                UIRectFrame(blockRect.insetBy(dx: 1, dy: 1))
                UIColor.black.set()
            }
        }
        
        for highlightedMove in highlightedMoves {
            highlightedMove.color.set()
            let blockRect = blockRectCalculator(highlightedMove.move.x, highlightedMove.move.y).insetBy(dx: 1, dy: 1)
            UIRectFillUsingBlendMode(blockRect, .normal)
        }
    }
}

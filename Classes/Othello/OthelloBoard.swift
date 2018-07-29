//
//  OthelloBoard.swift
//  Othello
//
//  Created by Petteri Kamppuri on 26.3.2016.
//  Copyright © 2016 Petteri Kamppuri. All rights reserved.
//

import Foundation


struct OthelloBoard {
    fileprivate var whitePieces: UInt64
    fileprivate var blackPieces: UInt64
    
    enum Color {
        case black
        case white
        
        func opposite() -> Color {
            switch self {
            case .black:
                return .white
            case .white:
                return .black
            }
        }
    }
    
    enum Piece {
        case color(OthelloBoard.Color)
        case empty
    }
    
    init() {
        self.whitePieces = 0
        self.blackPieces = 0
    }
    
    init(other: OthelloBoard) {
        whitePieces = other.whitePieces
        blackPieces = other.blackPieces
    }
    
    func numberOfWhitePieces() -> Int {
        return numberOfBitsSet(self.whitePieces)
    }
    
    func numberOfBlackPieces() -> Int {
        return numberOfBitsSet(self.blackPieces)
    }
    
    var numberOfPieces: Int {
        return numberOfBitsSet(self.whitePieces | self.blackPieces)
    }
    
    var isFull: Bool {
        return (self.numberOfPieces) == (self.boardWidth * self.boardHeight)
    }
    
    var boardWidth: Int {
        return 8
    }
    
    var boardHeight: Int {
        return 8
    }
    
    func iterateBoard(_ block: (_ x: Int, _ y: Int, _ piece: Piece) -> Void) {
        for y in 0..<self.boardHeight {
            for x in 0..<self.boardWidth {
                block(x, y, self[x, y])
            }
        }
    }
    
    func pieceAt(x: Int, y: Int) -> Piece {
        return self[x, y]
    }
    
    subscript(x: Int, y: Int) -> Piece {
        get {
            if isWhiteAt(x: x, y: y) {
                return Piece.color(Color.white)
            } else if isBlackAt(x: x, y: y) {
                return Piece.color(Color.black)
            } else {
                return Piece.empty
            }
        }
        set(newValue) {
            let bitmask = bitmaskAt(x: x, y: y)
            let allBits: UInt64 = 0xffffffffffffffff
            
            switch newValue {
            case .color(let color):
                switch color {
                case .white:
                    self.whitePieces = self.whitePieces | bitmask
                    self.blackPieces = self.blackPieces & (allBits ^ bitmask)
                case .black:
                    self.whitePieces = self.whitePieces & (allBits ^ bitmask)
                    self.blackPieces = self.blackPieces | bitmask
                }
            case .empty:
                self.whitePieces = self.whitePieces & (allBits ^ bitmask)
                self.blackPieces = self.blackPieces & (allBits ^ bitmask)
            }
        }
    }
    
    func isValidCoordinate(x: Int, y: Int) -> Bool {
        if x < 0 || x >= self.boardWidth {
            return false
        }
        if y < 0 || y >= self.boardHeight {
            return false
        }
        
        return true
    }
    
    func isEmptyAt(x: Int, y: Int) -> Bool {
        return isWhiteAt(x: x, y: y) == false && isBlackAt(x: x, y: y) == false
    }
    
    func isWhiteAt(x: Int, y: Int) -> Bool {
        return (self.whitePieces & bitmaskAt(x: x, y: y)) != 0
    }
    
    func isBlackAt(x: Int, y: Int) -> Bool {
        return (self.blackPieces & bitmaskAt(x: x, y: y)) != 0
    }
    
    private func bitmaskAt(x: Int, y: Int) -> UInt64 {
        assert(0 <= x && x < self.boardWidth)
        assert(0 <= y && y < self.boardHeight)
        
        let bitmask: UInt64 = (1 << UInt64(x)) << (8 * UInt64(y))
        
        return bitmask
    }
}

extension OthelloBoard : Equatable {}

func ==(lhs: OthelloBoard, rhs: OthelloBoard) -> Bool {
    return lhs.whitePieces == rhs.whitePieces && lhs.blackPieces == rhs.blackPieces
}

extension OthelloBoard : Hashable {
    var hashValue: Int {
        return Int(truncatingIfNeeded: self.whitePieces | self.blackPieces)
    }
}

extension OthelloBoard : CustomStringConvertible {
    var description: String {
        var res: String = ""
        for y in 0..<self.boardHeight {
            for x in 0..<self.boardWidth {
                let pieceSymbol: String
                switch self.pieceAt(x: x, y: y) {
                case .empty:
                    pieceSymbol = "."
                case .color(let color):
                    switch color {
                    case .white:
                        pieceSymbol = "O"
                    case .black:
                        pieceSymbol = "X"
                    }
                }
                
                res += pieceSymbol
            }
            res += "\n"
        }
        return res
    }
}

extension OthelloBoard : CustomDebugStringConvertible {
    var debugDescription: String {
        return self.description
    }
}



func numberOfBitsSet(_ value: UInt64) -> Int {
    // From: https://en.wikipedia.org/wiki/Hamming_weight
    let m1: UInt64  = 0x5555555555555555 //binary: 0101...
    let m2: UInt64  = 0x3333333333333333 //binary: 00110011..
    let m4: UInt64  = 0x0f0f0f0f0f0f0f0f //binary:  4 zeros,  4 ones ...
    //let m8: UInt64  = 0x00ff00ff00ff00ff //binary:  8 zeros,  8 ones ...
    //let m16: UInt64 = 0x0000ffff0000ffff //binary: 16 zeros, 16 ones ...
    //let m32: UInt64 = 0x00000000ffffffff //binary: 32 zeros, 32 ones
    //let hff: UInt64 = 0xffffffffffffffff //binary: all ones
    //let h01: UInt64 = 0x0101010101010101 //the sum of 256 to the power of 0,1,2,3...
    
    var x = value
    
    x -= (x >> UInt64(1)) & m1             //put count of each 2 bits into those 2 bits
    x = (x & m2) + ((x >> UInt64(2)) & m2) //put count of each 4 bits into those 4 bits
    x = (x + (x >> UInt64(4))) & m4        //put count of each 8 bits into those 8 bits
    x += x >>  UInt64(8)  //put count of each 16 bits into their lowest 8 bits
    x += x >> UInt64(16)  //put count of each 32 bits into their lowest 8 bits
    x += x >> UInt64(32)  //put count of each 64 bits into their lowest 8 bits
    
    return Int(x & 0x7f)
}

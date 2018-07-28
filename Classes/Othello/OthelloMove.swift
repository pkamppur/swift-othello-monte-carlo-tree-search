//
//  OthelloMove.swift
//  Othello
//
//  Created by Petteri Kamppuri on 28.7.2018.
//  Copyright © 2018 Petteri Kamppuri. All rights reserved.
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



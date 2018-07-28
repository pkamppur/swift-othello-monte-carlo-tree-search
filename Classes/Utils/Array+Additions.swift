//
//  Array+Additions.swift
//  Othello
//
//  Created by Petteri Kamppuri on 28.7.2018.
//  Copyright © 2018 Petteri Kamppuri. All rights reserved.
//

import Foundation


extension Array {
    func randomItem() -> Element {
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

//
//  ObjectCollisionCategory.swift
//  AR Basketball
//
//  Created by Михаил Медведев on 26/05/2019.
//  Copyright © 2019 Михаил Медведев. All rights reserved.
//

import Foundation

struct ObjectCollisionCategory: OptionSet {
    let rawValue: Int
    
    static let none = ObjectCollisionCategory(rawValue: 0)
    static let topPlane = ObjectCollisionCategory(rawValue: 1)
    static let bottomPlane = ObjectCollisionCategory(rawValue: 4)
    static let ball = ObjectCollisionCategory(rawValue: 3 )
}

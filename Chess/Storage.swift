//
//  Storage.swift
//  Chess
//
//  Created by Khislatjon Valijonov on 09/05/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

@propertyWrapper public struct UserDefaultWrapper<Value> {
    public let key: String
    public let storage: UserDefaults = .standard
    
    public init(key: String) {
        self.key = key
    }
    
    public var wrappedValue: Value? {
        get {
            storage.value(forKey: key) as? Value
        }
        
        set {
            storage.setValue(newValue, forKey: key)
            storage.synchronize()
        }
    }
}

class Storage {
    static let shared = Storage()
    
    @UserDefaultWrapper(key: "boardTheme")
    var boardTheme: String?
}

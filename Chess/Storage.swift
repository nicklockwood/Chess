//
//  Storage.swift
//  Chess
//
//  Created by Khislatjon Valijonov on 09/05/24.
//  Copyright © 2024 Nick Lockwood. All rights reserved.
//

import Foundation

@propertyWrapper struct UserDefaultWrapper<Value> {
    let key: String
    let `default`: Value
    let storage: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            storage.value(forKey: key) as? Value ?? `default`
        }
        set {
            storage.setValue(newValue, forKey: key)
            storage.synchronize()
        }
    }
}

class Storage {
    static let shared = Storage()

    @UserDefaultWrapper(key: "boardTheme", default: nil)
    var boardTheme: String?

    @UserDefaultWrapper(key: "flipBlackWhenHuman", default: false)
    var flipBlackWhenHuman: Bool
}

//
//  CommonExtensions.swift
//  RickyBuggyBright
//
//  Created by Paweł Czerwinski on 14/03/2026.
//

import Foundation

struct IndexWithId: Identifiable, Equatable {
    let index: Int
    let id: Int
}

extension Result {
    var _isSuccess: Bool {
        if case .success = self {
            return true
        } else {
            return false
        }
    }
}

struct WeakReference<T: AnyObject> {
    weak var value: T?
}

func removeDead<Key: Hashable, T: AnyObject>(_ cache: inout [Key: WeakReference<T>]) {
    var toRemove: [Key] = []
    for (key, value) in cache {
        if value.value == nil {
            toRemove.append(key)
        }
    }
    for key in toRemove {
        cache.removeValue(forKey: key)
    }
}

private let nullObject = NSObject()

extension ObjectIdentifier {
    init(_ x: AnyObject?) {
        self.init(x ?? nullObject)
    }
}

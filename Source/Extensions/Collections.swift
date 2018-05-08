//
//  Created by Pierluigi Cifani on 18/02/16.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

extension Sequence {
    public func find(predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Iterator.Element? {
        for element in self {
            if try predicate(element) {
                return element
            }
        }
        return nil
    }
}

extension Collection {
    /// Return a copy of `self` with its elements shuffled
    public func shuffled() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffle()
        return list
    }

    public var randomElement: Iterator.Element {
        return self.shuffled()[0]
    }

    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    public subscript(safe index: Index) -> Element? {
        return index >= startIndex && index < endIndex
            ? self[index]
            : nil
    }
}

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in startIndex ..< endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
            guard i != j else { continue }
            self.swapAt(i, j)
        }
    }
}

extension Array {
    mutating public func moveItem(fromIndex oldIndex: Index, toIndex newIndex: Index) {
        insert(remove(at: oldIndex), at: newIndex)
    }
}

extension Dictionary {
    init(elements:[(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

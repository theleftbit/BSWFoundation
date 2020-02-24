//
//  Created by Pierluigi Cifani on 18/02/16.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

public extension Sequence {
    func find(predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Iterator.Element? {
        for element in self {
            if try predicate(element) {
                return element
            }
        }
        return nil
    }
}

public extension Collection {
    
    #if !swift(>=4.2)
    /// Return a copy of `self` with its elements shuffled
    func shuffled() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffle()
        return list
    }
    #endif
    
    var randomElement: Iterator.Element {
        return self.shuffled()[0]
    }

    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return index >= startIndex && index < endIndex
            ? self[index]
            : nil
    }
}

public extension MutableCollection where Index == Int {
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

public extension Array {
    mutating func moveItem(fromIndex oldIndex: Index, toIndex newIndex: Index) {
        insert(remove(at: oldIndex), at: newIndex)
    }
}

public extension Dictionary {
    init(elements:[(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

public struct SelectableArray<T>: Collection {
    public private(set) var selectedIndex: Int?
    public private(set) var options: [T]

    public enum SelectableArrayError: Swift.Error {
        case outOfBoundsIndex
    }
    
    public init(options: [T], selectedIndex: Int? = nil) {
        self.options = options
        self.selectedIndex = selectedIndex
    }

    public static func empty() -> SelectableArray<T> {
        return .init(options: [])
    }
    
    @discardableResult
    public mutating func select(atIndex: Int) -> T {
        selectedIndex = atIndex
        return options[atIndex]
    }
    
    public mutating func removeSelection() {
        selectedIndex = nil
    }

    public mutating func appendOption(_ option: T, andSelectIt: Bool = false) {
        options.append(option)
        if andSelectIt {
            selectedIndex = (options.count - 1)
        }
    }

    public func appendingOption(_ option: T, andSelectIt: Bool = false) -> SelectableArray<T> {
        var array = SelectableArray(options: options + [option])
        if andSelectIt {
            array.selectedIndex = (array.options.count - 1)
        }
        return array
    }

    public var selectedElement: T? {
        guard let selectedIndex = selectedIndex else { return nil }
        return options[selectedIndex]
    }
    
    // MARK: Collection
    
    public typealias Index = Array<T>.Index
    public typealias Element = Array<T>.Element
    public var startIndex: Index { return options.startIndex }
    public var endIndex: Index { return options.endIndex }
    
    // Required subscript, based on a dictionary index
    public subscript(index: Index) -> Iterator.Element {
        get { return options[index] }
    }

    // Method that returns the next index when iterating
    public func index(after i: Index) -> Index {
        return options.index(after: i)
    }
}

extension SelectableArray: Equatable where T: Equatable {
    
}

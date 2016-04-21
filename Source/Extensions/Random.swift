//
//  Created by Pierluigi Cifani on 12/2/15.
//
//

//MARK: - Random generation

public extension UInt32 {
    public static var random: UInt32 { return arc4random() }
}

public extension UInt64 {
    public static var random: UInt64 { return UInt64(arc4random()) << 32 | UInt64(arc4random()) }
    
    public var plusIntMin: Int {
        if self > UInt64(Int.max) { return Int(self - UInt64(Int.max) - 1) }
        else { return Int.min + Int(self) }
    }
}

public extension UInt64 { // distance for possibly very large ranges and closed intervals
    public static func distance(range: ClosedInterval<Int>) -> UInt64 { // TODO: Should be working with Int64 rather than Int
        if range.start == Int.min && range.end == Int.max {
            return UInt64.max
        } else if range.start < 0 && range.end >= 0 {
            let start = range.start == Int.min ? UInt64(Int.max) + 1 : UInt64(-range.start)
            return start + UInt64(range.end)
        } else {
            return UInt64(range.end - range.start)
        }
    }
}

public extension Int {
    public static func random(i: ClosedInterval<Int>) -> Int {
        let distance = UInt64.distance(i)
        if distance == 0 {
            return i.start
        } else if distance < UInt64(UInt32.max) {
            return i.start + Int(arc4random_uniform(UInt32(distance) + 1))
        } else if distance == UInt64.max {
            return UInt64.random.plusIntMin
        } else {
            return (UInt64.random % (distance + 1)).plusIntMin
        }
    }
}

public func random <C: CollectionType where C.Index == Int>
    (c: C) -> C.Generator.Element? {
        return c.random
}

public extension CollectionType where Index.Distance == Int { // random
    public var random: Generator.Element? {
        if isEmpty { return nil }
        let off = Int.random(0...(count - 1))
        let idx = startIndex.advancedBy(off)
        return self[idx]
    }
}

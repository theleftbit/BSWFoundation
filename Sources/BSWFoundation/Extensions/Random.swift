//
//  Created by Pierluigi Cifani on 12/2/15.
//
//
import Foundation

//MARK: - Random generation

public extension UInt32 {
    static var random: UInt32 { return arc4random() }
}

public extension UInt64 {
    static var random: UInt64 { return UInt64(arc4random()) << 32 | UInt64(arc4random()) }
    
    var plusIntMin: Int {
        if self > UInt64(Int.max) { return Int(self - UInt64(Int.max) - 1) }
        else { return Int.min + Int(self) }
    }
}

public extension UInt64 { // distance for possibly very large ranges and closed intervals
    static func distance(_ range: ClosedRange<Int>) -> UInt64 { // TODO: Should be working with Int64 rather than Int
        if range.lowerBound == Int.min && range.upperBound == Int.max {
            return UInt64.max
        } else if range.lowerBound < 0 && range.upperBound >= 0 {
            let start = range.lowerBound == Int.min ? UInt64(Int.max) + 1 : UInt64(-range.lowerBound)
            return start + UInt64(range.upperBound)
        } else {
            return UInt64(range.upperBound - range.lowerBound)
        }
    }
}

public extension Int {
    static func random(_ i: ClosedRange<Int>) -> Int {
        let distance = UInt64.distance(i)
        if distance == 0 {
            return i.lowerBound
        } else if distance < UInt64(UInt32.max) {
            return i.lowerBound + Int(arc4random_uniform(UInt32(distance) + 1))
        } else if distance == UInt64.max {
            return UInt64.random.plusIntMin
        } else {
            return (UInt64.random % (distance + 1)).plusIntMin
        }
    }
}

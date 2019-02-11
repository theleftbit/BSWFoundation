//
//  Created by Pierluigi Cifani on 11/02/2019.
//

@discardableResult
public func with<T>(_ item: T, update: (inout T) throws -> Void) rethrows -> T {
    var this = item
    try update(&this)
    return this
}

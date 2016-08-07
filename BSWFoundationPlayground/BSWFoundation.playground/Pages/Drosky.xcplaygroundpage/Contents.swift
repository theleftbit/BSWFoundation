//: [Previous](@previous)

import BSWFoundation
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

enum BSWEnvironment: Environment {
    case Production
    
    var basePath: String {
        switch self {
        case .Production:
            return "https://blurredsoftware.com/"
        }
    }
}

let drosky = Drosky(environment: BSWEnvironment.Production)
print(drosky.backgroundSessionID)

//: [Next](@next)

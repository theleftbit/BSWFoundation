//
//  Created by Pierluigi Cifani on 27/07/2019.
//

#if canImport(Combine)
import Combine
import Task
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias CombineTask<T> = Combine.Future<T, Swift.Error>

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Task {
    var future: CombineTask<Success> {
        return .init { (promise) in
            self.upon(DispatchQueue.any()) { (result) in
                switch result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    var publisher: AnyPublisher<Success, Error> {
        return future.eraseToAnyPublisher()
    }
}

#endif


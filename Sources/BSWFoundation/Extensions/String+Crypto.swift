//
//  Created by Pierluigi Cifani on 13/06/2019.
//


import Crypto
import Foundation

public extension String {
    
    func hmac(algorithm: CryptoAlgorithm, key: String) -> String {
        let keyData = Data(key.utf8)
        let messageData = Data(self.utf8)
        let key = SymmetricKey(data: keyData)
        let hmac: Data
        switch algorithm {
        case .SHA256:
            hmac = Data(HMAC<SHA256>
                .authenticationCode(for: messageData, using: key))
        case .SHA384:
            hmac = Data(HMAC<SHA384>
                .authenticationCode(for: messageData, using: key))
        case .SHA512:
            hmac = Data(HMAC<SHA512>
                .authenticationCode(for: messageData, using: key))
        }
        
        return stringFromResult(result: [UInt8](hmac), length: algorithm.digestLength)
    }
    
    private func stringFromResult(result: [UInt8], length: Int) -> String {
        result.prefix(length).map { String(format: "%02x", $0) }.joined()
    }

    enum CryptoAlgorithm {
        case SHA256, SHA384, SHA512
        
        fileprivate var digestLength: Int {
            switch self {
            case .SHA256:   return 32
            case .SHA384:   return 48
            case .SHA512:   return 64
            }
        }
    }
}

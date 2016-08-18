//
//  Created by Pierluigi Cifani on 04/07/16.
//  Copyright © 2016 SeenJobs. All rights reserved.
//

import Foundation

public class ProgressObserver: NSObject {
    
    fileprivate let onUpdate: (Progress) -> Void
    fileprivate let progress: Progress
    
    public init(progress: Progress, onUpdate: @escaping (Progress) -> Void) {
        self.progress = progress
        self.onUpdate = onUpdate
        super.init()
        progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
    }
    
    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [String : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let progress = object as? Progress , progress == self.progress {
            DispatchQueue.main.async {
                self.onUpdate(progress)
            }
        }
    }
}

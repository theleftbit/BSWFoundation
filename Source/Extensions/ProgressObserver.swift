//
//  Created by Pierluigi Cifani on 04/07/16.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

public class ProgressObserver: NSObject {
    
    fileprivate let onUpdate: (Progress) -> Void
    fileprivate let progress: Progress
    
    private static var kvoContext = false
    
    public init(progress: Progress, onUpdate: @escaping (Progress) -> Void) {
        self.progress = progress
        self.onUpdate = onUpdate
        super.init()
        progress.addObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), options: .new, context: &ProgressObserver.kvoContext)
    }
    
    deinit {
        progress.removeObserver(self, forKeyPath: #keyPath(Progress.fractionCompleted), context: &ProgressObserver.kvoContext)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &ProgressObserver.kvoContext, object as AnyObject === progress  else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        DispatchQueue.main.async {
            self.onUpdate(self.progress)
        }
    }
}

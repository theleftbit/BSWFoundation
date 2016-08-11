//
//  Created by Pierluigi Cifani on 04/07/16.
//  Copyright © 2016 SeenJobs. All rights reserved.
//

import Foundation

public class ProgressObserver: NSObject {
    
    private let onUpdate: NSProgress -> Void
    private let progress: NSProgress
    
    public init(progress: NSProgress, onUpdate: NSProgress -> Void) {
        self.progress = progress
        self.onUpdate = onUpdate
        super.init()
        progress.addObserver(self, forKeyPath: "fractionCompleted", options: .New, context: nil)
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if let progress = object as? NSProgress where progress == self.progress {
            dispatch_async(dispatch_get_main_queue()) {
                self.onUpdate(progress)
            }
        }
    }
}

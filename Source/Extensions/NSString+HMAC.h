//
//  Created by Pierluigi Cifani on 12/10/15.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HMAC)

- (NSString *)sha256WithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

//
//  Created by Pierluigi Cifani on 12/10/15.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

#import "NSString+HMAC.h"
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@implementation NSString (HMAC)

- (NSString *)sha256WithKey:(NSString *)key {

    NSInteger digestLength = CC_SHA256_DIGEST_LENGTH;
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cMessage = [self cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[digestLength];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cMessage, strlen(cMessage), result);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:result
                                          length:sizeof(result)];
    
    return [HMAC base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
}

@end

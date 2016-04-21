//
//  Created by Pierluigi Cifani on 3/14/16.
//  Copyright © 2016 Wallapop SL. All rights reserved.
//

import Foundation

extension NSLocale {
    class func localeFromCurrencyCode(currencyCode: String) -> NSLocale {
        
        if let cachedLocale = PriceFormatter.localeCache.objectForKey(currencyCode) as? NSLocale {
            return cachedLocale
        }
        
        for localeID in NSLocale.availableLocaleIdentifiers() {
            let locale = NSLocale(localeIdentifier: localeID)
            if let currencyCode_ = locale.objectForKey(NSLocaleCurrencyCode) as? String
                where currencyCode == currencyCode_ {
                    PriceFormatter.localeCache.setObject(locale, forKey: currencyCode)
                    return locale
            }
        }
        
        return NSLocale.currentLocale()
    }
    
    func currencyCode() -> String {
        return self.objectForKey(NSLocaleCurrencyCode) as? String ?? "USD"
    }
    
    func formattedPrice(price: NSNumber) -> String {
        
        PriceFormatter.priceFormatter.locale = self
        PriceFormatter.priceFormatter.maximumFractionDigits = price.isFraction ? 2 : 0
        
        if let cachedValue = PriceFormatter.priceFormattedCache.objectForKey(NSLocale.keyForPrice(price, locale:self)) as? String {
            return cachedValue
        } else if let formattedPrice = PriceFormatter.priceFormatter.stringFromNumber(price) {
            PriceFormatter.priceFormattedCache.setObject(formattedPrice, forKey: NSLocale.keyForPrice(price, locale:self))
            return formattedPrice
        } else {
            return PriceFormatter.priceFormatter.stringFromNumber(0)!
        }
    }
    
    private static func keyForPrice(price: NSNumber, locale: NSLocale) -> String {
        return "\(price)_\(locale.localeIdentifier)"
    }
}

extension NSNumber {
    var isInteger: Bool {
        var rounded = decimalValue
        NSDecimalRound(&rounded, &rounded, 0, NSRoundingMode.RoundDown)
        return NSDecimalNumber(decimal: rounded) == self
    }
    
    var isFraction: Bool { return !isInteger }
}

private struct PriceFormatter {
    static private let priceFormatter: NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.formatterBehavior = .Behavior10_4
        formatter.numberStyle = .CurrencyStyle
        return formatter
    }()
    
    static private let priceFormattedCache = NSCache()
    static private let localeCache = NSCache()
}

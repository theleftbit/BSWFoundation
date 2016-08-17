//
//  Created by Pierluigi Cifani on 3/14/16.
//  Copyright © 2016 Blurred Software SL SL. All rights reserved.
//

import Foundation

extension NSLocale {
    public class func localeFromCurrencyCode(_ currencyCode: String) -> NSLocale {
        
        if let cachedLocale = PriceFormatter.localeCache.object(forKey: currencyCode) as? NSLocale {
            return cachedLocale
        }
        
        for localeID in NSLocale.availableLocaleIdentifiers {
            let locale = NSLocale(localeIdentifier: localeID)
            if let currencyCode_ = (locale as NSLocale).object(forKey: NSLocale.Key.currencyCode) as? String
                , currencyCode == currencyCode_ {
                    PriceFormatter.localeCache.setObject(locale, forKey: currencyCode)
                    return locale
            }
        }
        
        return NSLocale.current
    }
    
    public func currencyCode() -> String {
        return (self as NSLocale).object(forKey: NSLocale.Key.currencyCode) as? String ?? "USD"
    }
    
    public func formattedPrice(_ price: NSNumber) -> String {
        
        PriceFormatter.priceFormatter.locale = self as Locale!
        PriceFormatter.priceFormatter.maximumFractionDigits = price.isFraction ? 2 : 0
        
        if let cachedValue = PriceFormatter.priceFormattedCache.object(forKey: NSLocale.keyForPrice(price, locale:self)) as? String {
            return cachedValue
        } else if let formattedPrice = PriceFormatter.priceFormatter.string(from: price) {
            PriceFormatter.priceFormattedCache.setObject(formattedPrice, forKey: NSLocale.keyForPrice(price, locale:self))
            return formattedPrice
        } else {
            return PriceFormatter.priceFormatter.string(from: 0)!
        }
    }
    
    fileprivate static func keyForPrice(_ price: NSNumber, locale: NSLocale) -> String {
        return "\(price)_\(locale.localeIdentifier)"
    }
}

extension NSNumber {
    public var isInteger: Bool {
        var rounded = decimalValue
        NSDecimalRound(&rounded, &rounded, 0, NSDecimalNumber.RoundingMode.down)
        return NSDecimalNumber(decimal: rounded) == self
    }
    
    public var isFraction: Bool { return !isInteger }
}

private struct PriceFormatter {
    static fileprivate let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        return formatter
    }()
    
    static fileprivate let priceFormattedCache = NSCache()
    static fileprivate let localeCache = NSCache()
}

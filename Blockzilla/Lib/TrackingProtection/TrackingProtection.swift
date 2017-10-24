//
//  BlockList.swift
//  Blockzilla
//
//  Created by Jeff Boek on 10/24/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

import Foundation

protocol BlockListChecker {
    func isBlocked(url: URL) -> BlockLists.List?
}

class TrackingProtection: BlockListChecker {
    static let shared = TrackingProtection()
    
    var blockLists = BlockLists()
    private init() { }
    
    func isBlocked(url: URL) -> BlockLists.List? {
        print(Utils.getEnabledLists())
        let enabledLists = Utils.getEnabledLists().flatMap(BlockLists.List.init(rawValue:))
        return blockLists.urlIsInList(url).flatMap { return enabledLists.contains($0) ? $0 : nil }
    }
}

class BlockLists {
    class Rule {
        let regex: NSRegularExpression
        let loadType: LoadType
        let resourceType: ResourceType
        let domainExceptions: [NSRegularExpression]?
        let list: List
        
        init(regex: NSRegularExpression, loadType: LoadType, resourceType: ResourceType, domainExceptions: [NSRegularExpression]?, list: List) {
            self.regex = regex
            self.loadType = loadType
            self.resourceType = resourceType
            self.domainExceptions = domainExceptions
            self.list = list
        }
    }
    
    fileprivate var blockRules = [Rule]()
    
    enum LoadType {
        case all
        case thirdParty
    }
    
    enum ResourceType {
        case all
        case font
    }
    
    enum List: String {
        case advertising = "disconnect-advertising"
        case analytics = "disconnect-analytics"
        case content = "disconnect-content"
        case social = "disconnect-social"
        
        var fileName: String { return self.rawValue }

        static var all: [List] { return [.advertising, .analytics, .content, .social] }
    }
    
    init() {
        for blockList in List.all {
            let path = pathForResource(blockList.fileName)
            let json = try? Data(contentsOf: URL(fileURLWithPath: path))
            let list = try! JSONSerialization.jsonObject(with: json!, options: []) as! [[String: AnyObject]]
            for rule in list {
                let trigger = rule["trigger"] as! [String: AnyObject]
                let filter = trigger["url-filter"] as! String
                let filterRegex = try! NSRegularExpression(pattern: filter, options: [])
                
                let domainExceptions: [NSRegularExpression]? = (trigger["unless-domain"] as? [String])?.map { domain in
                    // Convert the domain exceptions into regular expressions.
                    var regex = domain + "$"
                    if regex.characters.first == "*" {
                        regex = "." + regex
                    }
                    regex = regex.replacingOccurrences(of: ".", with: "\\.")
                    return try! NSRegularExpression(pattern: regex, options: [])
                }
                
                // Only "third-party" is supported; other types are not used in our block lists.
                let loadTypes = trigger["load-type"] as? [String] ?? []
                let loadType = loadTypes.contains("third-party") ? LoadType.thirdParty : .all
                
                // Only "font" is supported; other types are not used in our block lists.
                let resourceTypes = trigger["resource-type"] as? [String] ?? []
                let resourceType = resourceTypes.contains("font") ? ResourceType.font : .all
                
                blockRules.append(Rule(regex: filterRegex, loadType: loadType, resourceType: resourceType, domainExceptions: domainExceptions, list: blockList))
            }
        }
    }
    
    private func pathForResource(_ resource: String) -> String {
        return Bundle.main.path(forResource: resource, ofType: "json")!
    }
    
    func urlIsInList(_ url: URL) -> List? {
        let resourceString = url.absoluteString
        let resourceRange = NSMakeRange(0, resourceString.characters.count)

        domainSearch: for rule in blockRules {
            // First, test the top-level filters to see if this URL might be blocked.
            if rule.regex.firstMatch(in: resourceString, options: .anchored, range: resourceRange) != nil {
                // Check the domain exceptions. If a domain exception matches, this filter does not apply.
                for domainRegex in (rule.domainExceptions ?? []) {
                    if domainRegex.firstMatch(in: resourceString, options: [], range: resourceRange) != nil {
                        continue domainSearch
                    }
                }

                return rule.list
            }
        }
        
        return nil
    }
}


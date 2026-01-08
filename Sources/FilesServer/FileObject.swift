//
//  FileObject.swift
//  FileProvider
//
//  Created by kintan
//

import Foundation

/// Containts path, url and attributes of a file or resource.  参考URLResourceValues
public final class FileObject: Hashable, Sendable {
    /// A `Dictionary` contains file information,  using `URLResourceKey` keys.
    public let allValues: [URLResourceKey: Sendable]
    /**
     m3u8的ext 例如 tvg-logo="https://image.com" group-title="test"
     */
    public let extinf: [String: String]?

    public init(url: URL, allValues: [URLResourceKey: Sendable], extinf: [String: String]? = nil) {
        var allValues = allValues
        allValues[.fileURLKey] = url
        self.allValues = allValues
        self.extinf = extinf
    }

    public convenience init(rootURL: URL, allValues: [URLResourceKey: Sendable]) {
        let url: URL
        if let value = allValues[.fileURLKey] as? URL {
            url = value
        } else {
            if allValues[.fileResourceTypeKey] as? URLFileResourceType == .directory {
                url = rootURL
            } else {
                url = rootURL.appendingPathComponent(allValues[.pathKey] as? String ?? "")
            }
        }
        self.init(url: url, allValues: allValues)
    }

    public convenience init(url: URL, path: String, isDirectory: Bool, modifiedDate: Date, size: Int64, authorization: String) {
        var allValues = [URLResourceKey: Sendable]()
        allValues[.pathKey] = path
        allValues[.nameKey] = url.lastPathComponent
        allValues[.contentModificationDateKey] = modifiedDate
        allValues[.fileSizeKey] = size
        allValues[.fileResourceTypeKey] = isDirectory ? URLFileResourceType.directory : .regular
        allValues[.authorization] = authorization
        self.init(url: url, allValues: allValues)
    }

    public convenience init(url: URL, name: String, path: String? = nil, isDirectory: Bool = false, group: String? = nil, thumbnail: URL? = nil) {
        var allValues = [URLResourceKey: Sendable]()
        allValues[.nameKey] = name
        allValues[.pathKey] = path ?? url.lastPathComponent
        allValues[.fileResourceTypeKey] = isDirectory ? URLFileResourceType.directory : .regular
        allValues[.groupKey] = group
        allValues[.thumbnailKey] = thumbnail
        self.init(url: url, allValues: allValues)
    }

    public convenience init(url: URL, name: String, path: String, isDirectory: Bool, childrensCount: Int? = nil) {
        var allValues = [URLResourceKey: Sendable]()
        allValues[.nameKey] = name
        allValues[.pathKey] = path
        allValues[.childrensCount] = childrensCount
        allValues[.fileResourceTypeKey] = isDirectory ? URLFileResourceType.directory : .regular
        self.init(url: url, allValues: allValues)
    }

    public convenience init(url: URL, name: String, extinf _: [String: String]) {
        var allValues = [URLResourceKey: Sendable]()
        allValues[.nameKey] = name
        allValues[.pathKey] = url.relativePath
        self.init(url: url, allValues: allValues)
    }

    public convenience init(url: URL, name: String, type: URLFileResourceType) {
        var allValues = [URLResourceKey: Sendable]()
        allValues[.nameKey] = name
        allValues[.pathKey] = url.relativePath
        allValues[.fileResourceTypeKey] = type
        self.init(url: url, allValues: allValues)
    }

    /// URL to access the resource, can be a relative URL against base URL.
    /// 现在init方法强制都有url。所以可以认为一定有url
    public var url: URL? {
        allValues[.fileURLKey] as? URL
    }

    /// Name of the file, usually equals with the last path component
    public var name: String {
        allValues[.nameKey] as? String ?? ""
    }

    /// Relative path of file object
    public var path: String {
        allValues[.pathKey] as? String ?? ""
    }

    /// Size of file on disk, return 0 for directories.
    @available(*, deprecated, message: "Use fileSize instead")
    public var size: Int64 {
        fileSize
    }

    public var fileSize: Int64 {
        allValues[.fileSizeKey] as? Int64 ?? 0
    }

    public var duration: Int16 {
        allValues[.durationKey] as? Int16 ?? -1
    }

    /// Count of children items of a driectory.
    public var childrensCount: Int? {
        allValues[.childrensCount] as? Int
    }

    /// The time contents of file has been created, returns nil if not set
    public var creationDate: Date? {
        allValues[.creationDateKey] as? Date
    }

    /// The time contents of file has been modified, returns nil if not set
    public var modifiedDate: Date? {
        allValues[.contentModificationDateKey] as? Date
    }

    /// return resource type of file, usually directory, regular or symLink
    public var type: URLFileResourceType {
        allValues[.fileResourceTypeKey] as? URLFileResourceType ?? .unknown
    }

    /// File is hidden either because begining with dot or filesystem flags
    /// Setting this value on a file begining with dot has no effect
    public var isHidden: Bool {
        allValues[.isHiddenKey] as? Bool ?? false
    }

    /// File can not be written
    public var isReadOnly: Bool {
        !(allValues[.isWritableKey] as? Bool ?? true)
    }

    public var authorization: String? {
        allValues[.authorization] as? String
    }

    public var thumbnail: URL? {
        allValues[.thumbnailKey] as? URL
    }

    public var group: String? {
        allValues[.groupKey] as? String
    }

    /// File is a Directory
    public var isDirectory: Bool {
        type == .directory
    }

    /// File is a normal file
    public var isRegularFile: Bool {
        type == .regular
    }

    /// File is a Symbolic link
    public var isSymLink: Bool {
        type == .symbolicLink
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(fileSize)
        hasher.combine(modifiedDate)
    }

    public static func == (lhs: FileObject, rhs: FileObject) -> Bool {
        if lhs === rhs {
            return true
        }
        if Swift.type(of: lhs) != Swift.type(of: rhs) {
            return false
        }

        if let rurl = rhs.allValues[.fileURLKey] as? URL, let lurl = lhs.allValues[.fileURLKey] as? URL {
            return rurl == lurl && lhs.fileSize == rhs.fileSize
        }
        return lhs.path == rhs.path && lhs.fileSize == rhs.fileSize && lhs.modifiedDate == rhs.modifiedDate
    }

    /// Determines sort kind by which item of File object
    public enum SortType: Sendable {
        /// Sorting by default Finder (case-insensitive) behavior
        case name
        /// Sorting by case-sensitive form of file name
        case nameCaseSensitive
        /// Sorting by case-in sensitive form of file name
        case nameCaseInsensitive
        /// Sorting by file type
        case `extension`
        /// Sorting by file modified date
        case modifiedDate
        /// Sorting by file creation date
        case creationDate
        /// Sorting by file modified date
        case fileSize
    }
}

extension FileObject {
    func mapPredicate() -> [String: Any] {
        let mapDict: [URLResourceKey: String] = [.fileURLKey: "url", .nameKey: "name", .pathKey: "path",
                                                 .fileSizeKey: "fileSize", .creationDateKey: "creationDate",
                                                 .contentModificationDateKey: "modifiedDate", .isHiddenKey: "isHidden",
                                                 .isWritableKey: "isWritable", .serverDateKey: "serverDate",
                                                 .entryTagKey: "entryTag", .mimeTypeKey: "mimeType"]
        let typeDict: [URLFileResourceType: String] = [.directory: "directory", .regular: "regular",
                                                       .symbolicLink: "symbolicLink", .unknown: "unknown"]
        var result = [String: Any]()
        for (key, value) in allValues {
            if let convertkey = mapDict[key] {
                result[convertkey] = value
            }
        }
        result["eTag"] = result["entryTag"]
        result["filesize"] = result["fileSize"]
        result["isReadOnly"] = isReadOnly
        result["isDirectory"] = isDirectory
        result["isRegularFile"] = isRegularFile
        result["isSymLink"] = isSymLink
        result["type"] = typeDict[type] ?? "unknown"
        return result
    }

    /// Converts macOS spotlight query for searching files to a query that can be used for `searchFiles()` method
    public static func convertPredicate(fromSpotlight query: NSPredicate) -> NSPredicate {
        let mapDict: [String: URLResourceKey] = [NSMetadataItemURLKey: .fileURLKey, NSMetadataItemFSNameKey: .nameKey,
                                                 NSMetadataItemPathKey: .pathKey, NSMetadataItemFSSizeKey: .fileSizeKey,
                                                 NSMetadataItemFSCreationDateKey: .creationDateKey, NSMetadataItemFSContentChangeDateKey: .contentModificationDateKey,
                                                 "kMDItemFSInvisible": .isHiddenKey, "kMDItemFSIsWriteable": .isWritableKey,
                                                 "kMDItemKind": .mimeTypeKey]

        if let cQuery = query as? NSCompoundPredicate {
            let newSub = cQuery.subpredicates.map { convertPredicate(fromSpotlight: $0 as! NSPredicate) }
            switch cQuery.compoundPredicateType {
            case .and: return NSCompoundPredicate(andPredicateWithSubpredicates: newSub)
            case .not: return NSCompoundPredicate(notPredicateWithSubpredicate: newSub[0])
            case .or: return NSCompoundPredicate(orPredicateWithSubpredicates: newSub)
            @unknown default: fatalError()
            }
        } else if let cQuery = query as? NSComparisonPredicate {
            var newLeft = cQuery.leftExpression
            var newRight = cQuery.rightExpression
            if newLeft.expressionType == .keyPath, let newKey = mapDict[newLeft.keyPath] {
                newLeft = NSExpression(forKeyPath: newKey.rawValue)
            }
            if newRight.expressionType == .keyPath, let newKey = mapDict[newRight.keyPath] {
                newRight = NSExpression(forKeyPath: newKey.rawValue)
            }
            return NSComparisonPredicate(leftExpression: newLeft, rightExpression: newRight, modifier: cQuery.comparisonPredicateModifier, type: cQuery.predicateOperatorType, options: cQuery.options)
        } else {
            return query
        }
    }
}

public extension [FileObject] {
    mutating func sort(by type: FileObject.SortType, ascending: Bool = true, isDirectoriesFirst: Bool = true) {
        sort {
            if isDirectoriesFirst {
                if $0.isDirectory, !($1.isDirectory) {
                    return true
                }
                if !($0.isDirectory), $1.isDirectory {
                    return false
                }
            }
            switch type {
            case .name:
                return ($0.name).localizedStandardCompare($1.name) == (ascending ? .orderedAscending : .orderedDescending)
            case .nameCaseSensitive:
                return ($0.name).localizedCompare($1.name) == (ascending ? .orderedAscending : .orderedDescending)
            case .nameCaseInsensitive:
                return ($0.name).localizedCaseInsensitiveCompare($1.name) == (ascending ? .orderedAscending : .orderedDescending)
            case .extension:
                let kind1 = $0.isDirectory ? "folder" : $0.path.pathExtension
                let kind2 = $1.isDirectory ? "folder" : $1.path.pathExtension
                return kind1.localizedCaseInsensitiveCompare(kind2) == (ascending ? .orderedAscending : .orderedDescending)
            case .modifiedDate:
                let fileMod1 = $0.modifiedDate ?? Date.distantPast
                let fileMod2 = $1.modifiedDate ?? Date.distantPast
                return ascending ? fileMod1 < fileMod2 : fileMod1 > fileMod2
            case .creationDate:
                let fileCreation1 = $0.creationDate ?? Date.distantPast
                let fileCreation2 = $1.creationDate ?? Date.distantPast
                return ascending ? fileCreation1 < fileCreation2 : fileCreation1 > fileCreation2
            case .fileSize:
                return ascending ? $0.fileSize < $1.fileSize : $0.fileSize > $1.fileSize
            }
        }
    }
}

public extension URLResourceKey {
    /// **FileProvider** returns url of file object.
    static let fileURLKey = URLResourceKey(rawValue: "NSURLFileURLKey")
    /// **FileProvider** returns modification date of file in server
    static let serverDateKey = URLResourceKey(rawValue: "NSURLServerDateKey")
    /// **FileProvider** returns HTTP ETag string of remote resource
    static let entryTagKey = URLResourceKey(rawValue: "NSURLEntryTagKey")
    /// **FileProvider** returns MIME type of file, if returned by server
    static let mimeTypeKey = URLResourceKey(rawValue: "NSURLMIMETypeIdentifierKey")
    /// **FileProvider** returns either file is encrypted or not
    static let isEncryptedKey = URLResourceKey(rawValue: "NSURLIsEncryptedKey")
    /// **FileProvider** count of items in directory
    static let childrensCount = URLResourceKey(rawValue: "MFPURLChildrensCount")
    /// 认证
    static let authorization = URLResourceKey(rawValue: "NSURLAuthorization")
    static let groupKey = URLResourceKey(rawValue: "NSURLGroupKey")
    static let durationKey = URLResourceKey(rawValue: "NSURLDurationKey")
    #if !os(macos)
    static let thumbnailKey = URLResourceKey(rawValue: "NSURLThumbnailKey")
    #endif
}

extension CharacterSet {
    static let filePathAllowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: ":"))
}

extension String {
    var pathExtension: String {
        (self as NSString).pathExtension
    }
}

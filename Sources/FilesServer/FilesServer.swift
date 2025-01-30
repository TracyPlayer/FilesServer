//
//  FilesServer.swift
//  FilesServer
//
//  Created by kintan on 12/26/24.
//

import Foundation
import KSPlayer

public protocol FilesServer {
    static func startDiscovery(url: URL) -> Self?
    static func scheme(isHttps: Bool) -> String
    var url: URL { get }
    func listShares() async throws -> [String]
    func connect(share: String) async throws
    func contentsOfDirectory(atPath path: String) async throws -> [FileObject]
    func play(path: String) -> AbstractAVIOContext?
}

public extension FilesServer {
    static func startDiscovery(isHttps: Bool, host: String, port: Int?, path: String?, username: String?, password: String?) -> Self? {
        let baseURL = scheme(isHttps: isHttps) + "://" + host
        // 处理端口
        guard var urlComponents = URLComponents(string: baseURL) else {
            return nil
        }
        urlComponents.port = port

        // 处理路径
        if let path, !path.isEmpty {
            let trimmedPath = path.hasPrefix("/") ? path : "/\(path)"
            urlComponents.path = trimmedPath
        } else {
            urlComponents.path = ""
        }
        if username?.isEmpty == false {
            urlComponents.user = username
        }
        if password?.isEmpty == false {
            urlComponents.password = password
        }
        guard let url = urlComponents.url else {
            return nil
        }
        return startDiscovery(url: url)
    }
}

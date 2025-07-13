//
//  FilesServer.swift
//  FilesServer
//
//  Created by kintan on 12/26/24.
//

import Foundation
import KSPlayer

public protocol FilesServer: Sendable {
    static var drives: [FilesServer] { get set }
    static func startDiscovery(url: URL) -> Self?
    static func scheme(isHttps: Bool) -> String
    var url: URL { get }
    @MainActor
    func listShares() async throws -> [String]
    @MainActor
    func connect(share: String) async throws
    func contentsOfDirectory(atPath path: String) async throws -> [FileObject]
    func removeItem(atPath path: String) async throws
    func createDirectory(atPath path: String) async throws
    func play(path: String) -> AbstractAVIOContext?
}

public extension FilesServer {
    static func startDiscovery(isHttps: Bool, host: String, port: Int?, path: String?, username: String?, password: String?) -> Self? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme(isHttps: isHttps)
        urlComponents.host = host
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

    @MainActor
    static func getServer(url: URL, name: String) async throws -> FilesServer? {
        if let drive = drives.first(where: { $0.url == url }) {
            return drive
        } else {
            var url = url
            if url.lastPathComponent == name {
                url.deleteLastPathComponent()
            }
            if let drive = startDiscovery(url: url) {
                try await drive.connect(share: name)
                drives.append(drive)
                return drive
            } else {
                return nil
            }
        }
    }

    static func play(url: URL) -> AbstractAVIOContext? {
        if let drive = drives.first(where: { url.absoluteString.hasPrefix($0.url.absoluteString) }) {
            let path = String(url.path.dropFirst(drive.url.path.count))
            return drive.play(path: path)
        } else {
            let path = url.path
            var components = URLComponents()
            components.scheme = url.scheme
            components.host = url.host
            components.port = url.port
            components.user = url.user
            components.password = url.password
            guard let url = components.url, let drive = startDiscovery(url: url) else {
                return nil
            }
            let semaphore = DispatchSemaphore(value: 0) // 初始信号量值为 0
            Task {
                do {
                    let shares = try await drive.listShares()
                    var share = shares.first { share in
                        // nfs的share带有/， 但是smb没有
                        path.hasPrefix("/" + share) || path.hasPrefix(share)
                    }
                    if share == nil {
                        share = shares.first
                    }
                    if let share {
                        try await drive.connect(share: share)
                    }
                    semaphore.signal()
                } catch {
                    KSLog(error)
                    semaphore.signal()
                }
            }
            semaphore.wait()
            drives.append(drive)
            var newPath = path
            newPath.removeFirst(drive.url.path.count)
            return drive.play(path: newPath)
        }
    }
}

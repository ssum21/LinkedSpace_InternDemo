//
//  AlbumCacheManager.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/25/25.
//

import Foundation

class AlbumCacheManager {
    
    /// 캐시 파일이 저장될 URL을 반환합니다.
    private static var cacheURL: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("generated_albums.json")
    }
    
    /// `[TripAlbum]` 배열을 JSON 파일로 저장합니다.
    static func save(albums: [TripAlbum]) {
        do {
            let data = try JSONEncoder().encode(albums)
            try data.write(to: cacheURL, options: [.atomic])
            print("앨범 캐시 저장 성공: \(cacheURL.path)")
        } catch {
            print("앨범 캐시 저장 실패: \(error)")
        }
    }
    
    /// JSON 파일로부터 `[TripAlbum]` 배열을 불러옵니다.
    static func load() -> [TripAlbum]? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            print("캐시 파일이 존재하지 않습니다.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let albums = try JSONDecoder().decode([TripAlbum].self, from: data)
            print("앨범 캐시 로드 성공!")
            return albums
        } catch {
            print("앨범 캐시 로드 실패: \(error)")
            return nil
        }
    }
    
    /// 캐시를 삭제합니다. (예: 새로고침 기능 구현 시 사용)
    static func clearCache() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}

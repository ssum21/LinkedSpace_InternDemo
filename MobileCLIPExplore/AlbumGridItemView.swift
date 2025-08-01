//
//  AlbumGridItemView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/17/25.
//

import SwiftUI

struct AlbumGridItemView: View {
    let album: TripAlbum
    
    // Calculate the total number of photos in the album
    private var photoCount: Int {
        album.days.reduce(0) { $0 + $1.moments.reduce(0) { $0 + $1.allAssetIds.count } }
    }
    
    // 대표 이미지 ID (첫날의 첫번째 POI의 대표 이미지)
    private var coverImageIdentifier: String? {
        album.days.first?.coverImage
    }

    var body: some View {
        VStack(alignment: .leading) {
            // 대표 이미지
            if let identifier = coverImageIdentifier {
                PhotoAssetView(identifier: identifier)
                    .aspectRatio(1, contentMode: .fill) // 1:1 비율
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .clipped()
            } else {
                // 이미지가 없을 경우 회색 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
            }
            
            // 앨범 제목과 사진 개수
            Text(album.albumTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.top, 4)
            
            Text("\(photoCount)장의 사진")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .cornerRadius(8)
        .shadow(radius: 2, x: 0, y: 1)
    }
}

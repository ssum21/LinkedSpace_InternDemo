//
//  SearchResultsGrid.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/23/25.
//

import SwiftUI

struct SearchResultsGrid: View {
    let results: [PhotoAsset]
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(results) { asset in
                    // PhotoAssetView를 재사용하여 각 사진을 표시합니다.
                    PhotoAssetView(identifier: asset.id)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        // 나중에 사진 상세 보기 기능을 위해 NavigationLink로 감쌀 수 있습니다.
                }
            }
        }
    }
}

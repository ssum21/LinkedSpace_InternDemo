import SwiftUI

struct MomentDetailView: View {
    // MARK: - Properties
    
    @Binding var moment: Moment
    @State private var showingPOIChooser = false

    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
    private let optionalColumns: [GridItem] = Array(repeating: .init(.flexible()), count: 4)

    // MARK: - Body
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Highlights Section
                ForEach($moment.highlights) { $highlight in
                    VStack(alignment: .leading) {
                        // ▼▼▼ [수정] 대표 사진에도 탭 제스처 추가 ▼▼▼
                        PhotoAssetView(identifier: highlight.representativeAssetId)
                            .aspectRatio(4/3, contentMode: .fill)
                            .clipped()
                            .cornerRadius(12)
                            .shadow(radius: 3, x: 0, y: 2)
                            .onTapGesture {
                                excludePhotoFromHighlight(identifier: highlight.representativeAssetId, from: highlight.id)
                            }
                        // ▲▲▲ [수정] 여기까지 ▲▲▲
                        
                        if highlight.assetIds.count > 1 {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(Array(highlight.assetIds.dropFirst()), id: \.self) { identifier in
                                    // ▼▼▼ [수정] 나머지 사진에도 탭 제스처 추가 ▼▼▼
                                    PhotoAssetView(identifier: identifier)
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipped()
                                        .onTapGesture {
                                            excludePhotoFromHighlight(identifier: identifier, from: highlight.id)
                                        }
                                    // ▲▲▲ [수정] 여기까지 ▲▲▲
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                
                // MARK: - Optional Photos Section
                if !moment.optionalAssetIds.isEmpty {
                    VStack(alignment: .leading) {
                        Text("추가할 만한 다른 사진들")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        LazyVGrid(columns: optionalColumns, spacing: 2) {
                            ForEach(moment.optionalAssetIds, id: \.self) { identifier in
                                PhotoAssetView(identifier: identifier)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                                    .cornerRadius(4)
                                    .grayscale(0.9) // 회색 처리
                                    .opacity(0.6)   // 반투명 처리
                                    .onTapGesture {
                                        includeOptionalPhoto(identifier: identifier)
                                    }
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .padding()
        }
        .navigationTitle(moment.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if moment.poiCandidates.count > 1 {
                    Button("장소 변경") {
                        showingPOIChooser = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingPOIChooser) {
            POIChooserView(moment: $moment)
        }
    }

    // MARK: - Helper Functions
    
    /// '추가할 만한 사진'을 탭했을 때, 새로운 하이라이트로 만들어 추가하는 함수
    private func includeOptionalPhoto(identifier: String) {
        moment.optionalAssetIds.removeAll { $0 == identifier }
        let newHighlight = Highlight(representativeAssetId: identifier, assetIds: [identifier])
        moment.highlights.append(newHighlight)
    }
    
    // ▼▼▼ [추가] 하이라이트의 사진을 탭했을 때 '추가할 만한 사진'으로 이동시키는 함수 ▼▼▼
    /// 하이라이트에 포함된 사진을 제외 목록으로 이동시킵니다.
    private func excludePhotoFromHighlight(identifier: String, from highlightId: UUID) {
        // 1. 해당 하이라이트의 인덱스를 찾습니다.
        guard let highlightIndex = moment.highlights.firstIndex(where: { $0.id == highlightId }) else { return }
        
        // 2. 하이라이트의 사진 목록에서 해당 ID를 제거합니다.
        moment.highlights[highlightIndex].assetIds.removeAll { $0 == identifier }
        
        // 3. 제외 목록(optionalAssetIds)에 사진 ID를 추가합니다.
        moment.optionalAssetIds.append(identifier)
        
        // 4. 만약 하이라이트가 비게 되면, 그 하이라이트 자체를 제거합니다.
        if moment.highlights[highlightIndex].assetIds.isEmpty {
            moment.highlights.remove(at: highlightIndex)
        } else {
            // 5. 만약 제거된 사진이 대표 사진이었다면, 남아있는 사진 중 첫 번째를 새 대표 사진으로 지정합니다.
            if moment.highlights[highlightIndex].representativeAssetId == identifier {
                moment.highlights[highlightIndex].representativeAssetId = moment.highlights[highlightIndex].assetIds.first!
            }
        }
    }
    // ▲▲▲ [추가] 여기까지 ▲▲▲
}

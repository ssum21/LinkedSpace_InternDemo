// [5] ImageSearchViewModel.swift

import SwiftUI
import Photos
import CoreML

@MainActor
class ImageSearchViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var searchQuery = ""
    @Published private(set) var searchResults: [PhotoAsset] = []
    
    // ▼▼▼ [수정] 중앙 서비스의 상태를 참조합니다. ▼▼▼
    @ObservedObject var photoService = PhotoProcessingService.shared

    // MARK: - Dependencies
    // 이 ViewModel은 이제 검색 로직에만 집중합니다.
    private let mobileCLIPClassifier: ZSImageClassification

    init() {
        // 모델 초기화는 그대로 유지
        let classifier = ZSImageClassification(model: defaultModel.factory())
        self.mobileCLIPClassifier = classifier
        Task { await mobileCLIPClassifier.load() }
    }
    
    /// 텍스트 쿼리 기반 이미지 검색
    func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.searchResults = []; return
        }
        guard photoService.isReady, !photoService.allPhotos.isEmpty else { return }

        // 로딩 상태는 서비스의 상태를 따르므로 직접 제어할 필요가 없습니다.
        
        guard let textEmbedding = await mobileCLIPClassifier.computeTextEmbeddings(promptArr: [searchQuery]).first else {
            return
        }

        var scoredAssets: [(asset: PhotoAsset, score: Float)] = []
        // 중앙 서비스의 사진 데이터를 사용합니다.
        for photo in photoService.allPhotos {
            guard let imageEmbedding = photo.imageEmbedding else { continue }
            let similarity = mobileCLIPClassifier.cosineSimilarity(imageEmbedding, textEmbedding)
            scoredAssets.append((asset: photo, score: similarity))
        }
        
        scoredAssets.sort { $0.score > $1.score }
        self.searchResults = scoredAssets.map { $0.asset }
    }
    
    // ▼▼▼ [수정] 사진 준비 함수는 중앙 서비스를 호출하는 역할만 합니다. ▼▼▼
    func preparePhotos() async {
        await photoService.processInitialPhotos(forceReload: true)
    }
}

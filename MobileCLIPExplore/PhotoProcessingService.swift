//
//  PhotoProcessingService.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

import SwiftUI
import Photos
import CoreML

@MainActor
class PhotoProcessingService: ObservableObject {
    static let shared = PhotoProcessingService()

    // MARK: - Published Properties for UI
    @Published private(set) var allPhotos: [PhotoAsset] = []
    @Published private(set) var statusMessage = "앱을 준비 중입니다..."
    @Published private(set) var isLoading = false
    @Published private(set) var isReady = false
    @Published var progress: Double = 0.0

    // MARK: - Dependencies
    private let mobileCLIPClassifier: ZSImageClassification

    // 외부에서 직접 인스턴스를 생성하지 못하도록 private으로 설정
    private init() {
        let classifier = ZSImageClassification(model: defaultModel.factory())
        self.mobileCLIPClassifier = classifier
        
        Task {
            await mobileCLIPClassifier.load()
        }
    }

    // MARK: - Core Logic
    
    /// 앱 시작 또는 필요 시 호출될 메인 함수. 최근 100장의 사진을 처리합니다.
    func processInitialPhotos(forceReload: Bool = false) async {
        // 이미 로딩이 완료되었고, 강제 새로고침이 아니라면 중단
        if isReady && !forceReload { return }
        
        // 이미 로딩 중이라면 중단
        guard !isLoading else { return }

        isLoading = true
        isReady = false
        statusMessage = "사진 보관함 접근 권한을 확인 중입니다..."
        
        guard await requestPhotoLibraryAccess() else {
            statusMessage = "사진 보관함 접근 권한이 필요합니다."
            isLoading = false
            return
        }
        
        statusMessage = "최근 사진 100장을 가져오는 중..."
        let allPHAssets = await findRecentAssets(limit: 100)
        
        guard !allPHAssets.isEmpty else {
            statusMessage = "사진 보관함에 분석할 이미지가 없습니다."
            isLoading = false
            return
        }
        
        self.allPhotos = await processAssets(allPHAssets)
        
        isLoading = false
        if !self.allPhotos.isEmpty {
            isReady = true
            statusMessage = "\(allPhotos.count)장의 사진 분석 완료! 검색 및 추억 만들기를 할 수 있습니다."
        } else {
            statusMessage = "분석할 사진을 찾지 못했습니다."
        }
    }
    
    // MARK: - Helper Functions (기존 ViewModel들의 함수를 통합)
    
    private func requestPhotoLibraryAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
    
    private func findRecentAssets(limit: Int) async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.fetchLimit = limit

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }
        // AlbumCreator가 시간순(오래된 순)을 필요로 하므로 정렬해서 반환
        return assets.sorted { $0.creationDate ?? Date() < $1.creationDate ?? Date() }
    }
    
    private func processAssets(_ assets: [PHAsset]) async -> [PhotoAsset] {
        var processedAssets: [PhotoAsset] = []
        let totalCount = assets.count
        
        for (index, asset) in assets.enumerated() {
            guard let location = asset.location, let creationDate = asset.creationDate else { continue }
            
            let embedding = await getEmbedding(for: asset)
            
            let photoAsset = PhotoAsset(id: asset.localIdentifier, asset: asset, location: location, creationDate: creationDate, imageEmbedding: embedding)
            processedAssets.append(photoAsset)
            
            let currentProgress = Double(index + 1) / Double(totalCount)
            self.progress = currentProgress
            self.statusMessage = "사진 분석 중... (\(index + 1)/\(totalCount))"
        }
        return processedAssets
    }

    private func getEmbedding(for asset: PHAsset) async -> MLMultiArray? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 256, height: 256), contentMode: .aspectFill, options: options) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    print("이미지 요청 에러: \(error.localizedDescription) for asset \(asset.localIdentifier)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let image = image, let pixelBuffer = image.toCVPixelBuffer() else {
                    continuation.resume(returning: nil)
                    return
                }
                Task {
                    let result = await self.mobileCLIPClassifier.computeImageEmbeddings(frame: pixelBuffer)
                    continuation.resume(returning: result?.embedding)
                }
            }
        }
    }
}

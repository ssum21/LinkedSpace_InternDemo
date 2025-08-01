// [16] AlbumCreatorView.swift

import SwiftUI
import Photos
import CoreML

struct AlbumCreatorView: View {
    // MARK: - State Properties
    @State private var isLoading = false // 앨범 생성(그룹화) 과정 중의 로딩 상태
    @State private var statusMessage = "추억을 만들기 위해 아래 버튼을 누르세요."
    @State private var generatedAlbums: [TripAlbum] = []

    // MARK: - Shared Services
    @ObservedObject private var photoService = PhotoProcessingService.shared
    
    // MARK: - Dependencies
    private let tripDetector = TripDetectorService()
    private let mobileCLIPClassifier: ZSImageClassification
    private let albumService: AlbumCreationService

    // MARK: - Layout
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 2)

    // ▼▼▼ [핵심 수정] 뷰가 생성될 때 캐시를 로드하는 init() 메서드를 추가합니다. ▼▼▼
    init() {
        // 의존성 초기화
        let classifier = ZSImageClassification(model: defaultModel.factory())
        self.mobileCLIPClassifier = classifier
        let engine = POIRankingEngine(classifier: classifier)
        self.albumService = AlbumCreationService(rankingEngine: engine, classifier: classifier)
        
        // 뷰가 처음 생성될 때 캐시에서 앨범을 로드합니다.
        // @State 프로퍼티를 init에서 수정하려면 _(언더스코어)를 사용해야 합니다.
        if let cachedAlbums = AlbumCacheManager.load(), !cachedAlbums.isEmpty {
            self._generatedAlbums = State(initialValue: cachedAlbums)
            self._statusMessage = State(initialValue: "최근에 생성된 추억을 불러왔습니다.")
        }
    }
    // ▲▲▲ [핵심 수정] 여기까지 ▲▲▲

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack {
                // 1. 사진 분석 서비스가 로딩 중일 때 (앱 최초 실행 시)
                if photoService.isLoading {
                    Spacer()
                    ProgressView(value: photoService.progress) {
                        Text(photoService.statusMessage).font(.caption).foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                
                // 2. 앨범이 이미 생성되어 있을 때
                } else if !generatedAlbums.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(generatedAlbums) { album in
                                NavigationLink(destination: TripAlbumView(album: album)) {
                                    AlbumGridItemView(album: album)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                
                // 3. 앨범이 아직 없을 때 (사진 분석은 끝난 상태)
                } else {
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text(statusMessage)
                        .font(.headline)
                        .padding(.top)
                    Spacer()
                    
                    // 앨범이 없을 때만 이 버튼이 보입니다.
                    Button(action: { Task { await createAlbumsFromProcessedPhotos() } }) {
                        Text(isLoading ? "그룹화 중..." : "분석된 사진으로 추억 만들기")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLoading ? Color.gray : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isLoading || !photoService.isReady)
                    .padding()
                }
            }
            .navigationTitle("For You")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 앨범이 있거나 없을 때 모두 새로고침 버튼을 제공합니다.
                    Button {
                        Task { await createAlbumsFromProcessedPhotos(forceFullReload: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(photoService.isLoading || isLoading)
                }
            }
            .task {
                // 뷰가 나타날 때마다 사진 분석 서비스를 실행 (내부적으로 중복 실행 방지됨)
                await photoService.processInitialPhotos()
            }
        }
    }

    // MARK: - Core Logic
    private func createAlbumsFromProcessedPhotos(forceFullReload: Bool = false) async {
        // 강제 새로고침 시, 사진 재분석부터 시작
        if forceFullReload {
            await photoService.processInitialPhotos(forceReload: true)
        }
        
        guard photoService.isReady, !photoService.allPhotos.isEmpty else {
            await MainActor.run { statusMessage = "사진 분석이 먼저 완료되어야 합니다." }
            return
        }

        await MainActor.run {
            isLoading = true
            generatedAlbums = []
            statusMessage = "추억을 그룹화하는 중..."
            AlbumCacheManager.clearCache() // 새로 만들기 전, 이전 캐시 삭제
        }
        
        let photoAssets = photoService.allPhotos
        let trips = tripDetector.detectTrips(from: photoAssets)
        
        var finalAlbums: [TripAlbum] = []
        for tripData in trips {
            do {
                let album = try await albumService.createAlbum(from: tripData)
                if !album.days.isEmpty {
                    finalAlbums.append(album)
                }
            } catch {
                print("앨범 생성 중 에러: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            self.generatedAlbums = finalAlbums
            AlbumCacheManager.save(albums: finalAlbums)
            if finalAlbums.isEmpty {
                self.statusMessage = "새로운 추억을 찾지 못했습니다. 다른 사진으로 시도해보세요."
            }
            self.isLoading = false
        }
    }
}

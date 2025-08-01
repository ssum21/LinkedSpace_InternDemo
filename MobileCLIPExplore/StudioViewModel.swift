//
//  StudioViewModel.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

import SwiftUI
import Combine
import MapKit

// StudioView에서 사용될 뷰 모드 (토글)
enum StudioViewMode {
    case trips, moments
}

@MainActor
class StudioViewModel: ObservableObject {
    
    // MARK: - Published Properties for UI
    
    /// 생성된 모든 앨범 데이터
    @Published var allAlbums: [TripAlbum] = []
    
    /// 현재 선택된 날짜
    @Published var currentDate: Date = Date()
    
    /// 'Trips' / 'Moments' 토글 상태
    @Published var viewMode: StudioViewMode = .moments
    
    /// 앨범 생성(그룹화) 중인지 여부
    @Published var isLoading: Bool = false
    
    /// 현재 선택된 날짜에 해당하는 필터링된 모먼트 배열
    @Published var momentsForSelectedDate: [Moment] = []
    
    /// 지도에 표시될 카메라 위치 (중심점, 확대/축소 수준)
    @Published var cameraPosition: MapCameraPosition = .automatic
    
    // MARK: - Dependencies (의존성)
    
    /// 앱 전역 사진 분석 서비스 (싱글턴)
    @ObservedObject var photoService = PhotoProcessingService.shared
    
    /// 앨범 생성 로직을 담당하는 서비스
    private let albumService: AlbumCreationService
    
    /// 사진들을 여행 단위로 묶는 서비스
    private let tripDetector = TripDetectorService()
    
    /// Combine 구독을 관리하기 위한 변수
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    init() {
        // 의존성 주입: 필요한 서비스들을 초기화합니다.
        let classifier = ZSImageClassification(model: defaultModel.factory())
        let engine = POIRankingEngine(classifier: classifier)
        self.albumService = AlbumCreationService(rankingEngine: engine, classifier: classifier)
        
        // 뷰 모델이 생성될 때 초기 데이터 로드를 시도합니다.
        loadInitialData()
        
        // --- 반응형 로직 설정 ---
        setupBindings()
    }
    
    // MARK: - Public Methods for View
    
    /// 앨범 콘텐츠를 생성하거나 새로고침하는 메인 함수
    func generateContent(forceReload: Bool = false) async {
        // 강제 새로고침 옵션이 켜져 있으면, 사진 분석부터 다시 시작합니다.
        if forceReload {
            await photoService.processInitialPhotos(forceReload: true)
        }
        
        // 사진 분석이 준비되지 않았거나, 사진이 없으면 중단합니다.
        guard photoService.isReady, !photoService.allPhotos.isEmpty else { return }

        self.isLoading = true
        
        // 1. 사진들을 여행 단위로 묶습니다.
        let photoAssets = photoService.allPhotos
        let trips = tripDetector.detectTrips(from: photoAssets)
        
        var finalAlbums: [TripAlbum] = []
        // 2. 각 여행 단위로 앨범을 생성합니다.
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
        
        // 3. 최종 결과를 Published 프로퍼티에 할당하고 캐시에 저장합니다.
        self.allAlbums = finalAlbums
        AlbumCacheManager.save(albums: finalAlbums)
        self.isLoading = false
    }
    
    /// 날짜를 하루 뒤로 이동합니다.
    func goToNextDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    }
    
    /// 날짜를 하루 앞으로 이동합니다.
    func goToPreviousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
    }
    
    // MARK: - Private Helper Methods
    
    /// 뷰 모델 초기화 시 캐시에서 데이터를 로드합니다.
    private func loadInitialData() {
        if let cachedAlbums = AlbumCacheManager.load(), !cachedAlbums.isEmpty {
            self.allAlbums = cachedAlbums
        } else {
            // 캐시가 없으면, 앨범 생성을 시도합니다.
            Task {
                await generateContent()
            }
        }
    }
    
    /// Combine을 사용하여 데이터 스트림을 바인딩합니다.
    private func setupBindings() {
        // `allAlbums` 또는 `currentDate`가 변경될 때마다,
        // `getMoments(for:from:)` 함수를 호출하여 그 결과를
        // `momentsForSelectedDate` 프로퍼티에 자동으로 할당합니다.
        Publishers.CombineLatest($allAlbums, $currentDate)
            .map { albums, date in
                self.getMoments(for: date, from: albums)
            }
            .assign(to: \.momentsForSelectedDate, on: self)
            .store(in: &cancellables)
            
        // `momentsForSelectedDate`가 변경될 때마다,
        // `updateMapRegion(for:)` 함수를 호출하여 지도 위치를 업데이트합니다.
        $momentsForSelectedDate
            .sink { [weak self] moments in
                self?.updateMapRegion(for: moments)
            }
            .store(in: &cancellables)
    }
    
    /// 특정 날짜에 해당하는 모먼트 배열을 모든 앨범에서 찾아 반환합니다.
    private func getMoments(for date: Date, from albums: [TripAlbum]) -> [Moment] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        // 모든 앨범 -> 모든 날짜(Day)를 순회하며 조건에 맞는 날짜를 찾습니다.
        for album in albums {
            if let day = album.days.first(where: { $0.date == dateString }) {
                // 해당 날짜를 찾으면 그 날의 모먼트들을 반환하고 종료합니다.
                return day.moments
            }
        }
        // 해당 날짜에 모먼트가 없으면 빈 배열을 반환합니다.
        return []
    }
    
    /// 주어진 모먼트들이 모두 보이도록 지도 영역을 계산하고 업데이트합니다.
    private func updateMapRegion(for moments: [Moment]) {
        // 모먼트가 없으면 기본 위치(샌프란시스코)를 보여줍니다.
        guard !moments.isEmpty else {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
            return
        }
        
        // 모든 모먼트의 모든 POI 후보 좌표를 하나의 배열로 합칩니다.
        let coordinates = moments.flatMap { $0.poiCandidates.map { $0.coordinate } }
        
        guard !coordinates.isEmpty else { return }
        
        // 모든 좌표를 포함하는 경계 사각형(bounding box)을 계산합니다.
        var minLat = coordinates.first!.latitude
        var maxLat = minLat
        var minLon = coordinates.first!.longitude
        var maxLon = minLon

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        // 계산된 경계 사각형을 기반으로 지도의 중심점과 확대/축소 수준(span)을 결정합니다.
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        // 경계가 너무 작아도 핀이 잘 보이도록 여유 공간(1.5배)을 줍니다.
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.5, longitudeDelta: (maxLon - minLon) * 1.5)
        
        // 최종적으로 계산된 지역(region)으로 카메라 위치를 업데이트합니다.
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

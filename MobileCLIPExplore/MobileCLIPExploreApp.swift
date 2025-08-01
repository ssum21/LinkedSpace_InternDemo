//
// For licensing see accompanying LICENSE file.
// Copyright (C) 2024 Apple Inc. All Rights Reserved.
//

import SwiftUI
import GooglePlaces // Google Places SDK 임포트

@main
struct MobileCLIPExploreApp: App {
    
    // MARK: - Initialization
    
    init() {
        // 앱이 시작될 때 Google Places SDK에 API 키를 제공합니다.
        // 이 키는 Info.plist 파일에 'GOOGLE_API_KEY'라는 이름으로 저장되어 있어야 합니다.
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_API_KEY") as? String, !apiKey.isEmpty else {
            fatalError("Google API Key not found or is empty in Info.plist. Please add it to your project configuration.")
        }
        GMSPlacesClient.provideAPIKey(apiKey)
    }
    
    // MARK: - Scene Body
    
    var body: some Scene {
        WindowGroup {
            // 앱의 메인 뷰로 MainTabView를 설정합니다.
            MainTabView()
                .task {
                    // 앱이 처음 화면에 표시될 때 한 번 실행됩니다.
                    // PhotoProcessingService를 통해 백그라운드에서
                    // 최근 사진을 가져와 분석하는 작업을 시작합니다.
                    // 이 서비스는 싱글턴(shared)이므로, 앱의 어느 곳에서든
                    // 이 분석 결과를 공유하여 사용할 수 있습니다.
                    await PhotoProcessingService.shared.processInitialPhotos()
                }
                // 앱의 전체적인 디자인 테마를 다크 모드로 우선 적용합니다.
                .preferredColorScheme(.dark)
        }
    }
}

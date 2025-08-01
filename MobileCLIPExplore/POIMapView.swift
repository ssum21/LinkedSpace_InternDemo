import SwiftUI
import MapKit

struct POIMapView: View {
    // 보여줄 POI 후보들 (상위 8개만 사용)
    let candidates: [POICandidate]
    
    // 지도의 시작 위치와 확대 수준을 관리
    @State private var cameraPosition: MapCameraPosition
    
    init(candidates: [POICandidate]) {
        self.candidates = Array(candidates.prefix(8))
        
        // ▼▼▼ [수정] 지도의 초기 카메라 위치를 설정합니다. ▼▼▼
        // 첫 번째 후보가 있으면 그 위치를 중심으로, 없으면 "샌프란시스코"를 중심으로 보여줍니다.
        let initialRegion = MKCoordinateRegion(
            center: candidates.first?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            latitudinalMeters: 1200, // 범위를 조금 더 넓게 조정
            longitudinalMeters: 1200
        )
        self._cameraPosition = State(initialValue: .region(initialRegion))
    }
    
    var body: some View {
        // annotationItems에 Identifiable 한 데이터 배열을 전달하여 지도에 핀을 표시합니다.
        Map(position: $cameraPosition) {
            ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                // 핀을 커스텀하기 위해 MapAnnotation을 사용합니다.
                Annotation(candidate.name, coordinate: candidate.coordinate) {
                    VStack(spacing: 2) {
                        Text("\(index + 1)") // 순위 텍스트
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(pinColor(for: index))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1)
                            )
                            .shadow(radius: 2)
                        
                        Image(systemName: "arrowtriangle.down.fill") // 핀 모양
                            .font(.caption)
                            .foregroundColor(pinColor(for: index))
                            .offset(y: -3)
                    }
                }
            }
        }
        // ▲▲▲ [수정] 여기까지 ▲▲▲
    }
    
    // 순위에 따라 핀 색상을 결정하는 함수
    private func pinColor(for rank: Int) -> Color {
        switch rank {
        case 0: return .systemRed
        case 1: return .systemOrange
        case 2: return .systemYellow
        case 3: return .systemGreen
        case 4: return .systemTeal
        case 5: return .systemBlue
        case 6: return .systemIndigo
        default: return .systemGray
        }
    }
}

// SwiftUI의 Color에 시스템 색상을 사용하기 위한 확장 (선택사항이지만 권장)
extension Color {
    static let systemRed = Color(uiColor: .systemRed)
    static let systemOrange = Color(uiColor: .systemOrange)
    static let systemYellow = Color(uiColor: .systemYellow)
    static let systemGreen = Color(uiColor: .systemGreen)
    static let systemTeal = Color(uiColor: .systemTeal)
    static let systemBlue = Color(uiColor: .systemBlue)
    static let systemIndigo = Color(uiColor: .systemIndigo)
    static let systemGray = Color(uiColor: .systemGray)
}

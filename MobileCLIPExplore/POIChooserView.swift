import SwiftUI
import MapKit // MapKit 임포트 추가

struct POIChooserView: View {
    @Binding var moment: Moment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            // ▼▼▼ [수정] 전체 뷰를 VStack으로 감싸서 지도와 리스트를 수직으로 배치합니다. ▼▼▼
            VStack(spacing: 0) {
                // 후보지가 있을 경우에만 지도 뷰를 보여줍니다.
                if !moment.poiCandidates.isEmpty {
                    POIMapView(candidates: moment.poiCandidates)
                        .frame(height: 300) // 지도 뷰의 높이를 300으로 고정
                }

                // 기존 리스트 UI는 그대로 유지합니다.
                List(moment.poiCandidates, id: \.self) { candidate in
                    Button(action: {
                        moment.name = candidate.name
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(candidate.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            
                            Text(String(format: "%.2f", candidate.score))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)

                            if moment.name == candidate.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title2)
                            }
                        }
                    }
                }
                .listStyle(.plain) // 리스트 스타일을 plain으로 변경하여 경계선을 줄입니다.
            }
            // ▲▲▲ [수정] 여기까지 ▲▲▲
            .navigationTitle("장소 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            // 뷰가 나타날 때 모든 후보지를 보여줄 수 있도록 지도 영역을 재계산합니다. (선택사항)
            .onAppear(perform: fitMapToCandidates)
        }
    }
    
    // 모든 후보 핀이 보이도록 지도 영역을 조정하는 함수 (선택사항)
    private func fitMapToCandidates() {
        // 이 기능은 POIMapView 내부에서 처리하거나,
        // 좀 더 복잡한 로직이 필요할 경우 여기서 MKCoordinateRegion을 계산하여
        // POIMapView에 전달할 수 있습니다.
        // 현재는 POIMapView의 init에서 기본 영역을 설정했으므로 생략 가능합니다.
    }
}

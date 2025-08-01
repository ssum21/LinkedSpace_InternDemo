//
//  SttudioView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

import SwiftUI
import MapKit

struct StudioView: View {
    // 뷰의 모든 상태와 로직을 관리하는 ViewModel
    @StateObject private var viewModel = StudioViewModel()
    
    // MARK: - Drawer State
    // 드로어(하단 패널)의 위치를 관리하는 상태 변수
    @State private var drawerOffset: CGFloat
    
    // 드로어가 최대로 올라갈 수 있는 위치 (상단 여백)
    private let minDrawerOffset: CGFloat = 100
    // 드로어가 최대로 내려갈 수 있는 위치 (화면 높이의 60%)
    private var maxDrawerOffset: CGFloat { UIScreen.main.bounds.height * 0.6 }

    // 날짜 포맷터
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    // 초기화 메서드에서 드로어의 시작 위치를 설정합니다.
    init() {
        _drawerOffset = State(initialValue: UIScreen.main.bounds.height * 0.6)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 1. 배경 지도
                Map(position: $viewModel.cameraPosition) {
                    // 현재 선택된 날짜의 모먼트들을 핀으로 표시
                    ForEach(viewModel.momentsForSelectedDate) { moment in
                        // 첫 번째 POI 후보의 위치에 핀을 표시합니다.
                        if let firstCandidate = moment.poiCandidates.first {
                            Annotation(moment.name, coordinate: firstCandidate.coordinate) {
                                mapPin() // 커스텀 핀 뷰
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .animation(.easeOut, value: viewModel.cameraPosition.region?.center.latitude)

                // 2. 콘텐츠 드로어 (하단 패널)
                momentDrawer
                    .offset(y: drawerOffset)
                    // 드래그 제스처로 드로어를 위아래로 움직일 수 있게 합니다.
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = drawerOffset + value.translation.height
                                // 드로어가 최소/최대 위치를 벗어나지 않도록 제한합니다.
                                drawerOffset = max(minDrawerOffset, min(maxDrawerOffset, newOffset))
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 3. 커스텀 네비게이션 바
                ToolbarItem(placement: .principal) { dateNavigator }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 데이터 새로고침 버튼
                    Button(action: {
                        Task { await viewModel.generateContent(forceReload: true) }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.photoService.isLoading)
                }
            }
            // 네비게이션 바 스타일 설정
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.7), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Subviews
    
    // 상단 날짜 네비게이션 UI
    private var dateNavigator: some View {
        HStack {
            Button(action: viewModel.goToPreviousDay) { Image(systemName: "chevron.left") }
            Spacer()
            Text(dateFormatter.string(from: viewModel.currentDate))
                .font(.system(size: 18, weight: .semibold))
                .id(viewModel.currentDate) // 날짜가 바뀔 때 텍스트 뷰를 새로 그리도록 ID 부여
                .transition(.opacity.combined(with: .move(edge: .top)))
            Spacer()
            Button(action: viewModel.goToNextDay) { Image(systemName: "chevron.right") }
        }
        .foregroundColor(.white)
        .frame(width: 220)
    }

    // 하단 드로어 UI
    private var momentDrawer: some View {
        VStack(spacing: 0) {
            // 드래그 핸들
            Capsule()
                .fill(Color.gray)
                .frame(width: 40, height: 5)
                .padding(.vertical, 8)
            
            // "Moments" / "Trips" 토글
            Picker("View Mode", selection: $viewModel.viewMode.animation()) {
                Text("Moments").tag(StudioViewMode.moments)
                Text("Trips").tag(StudioViewMode.trips)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            // 로딩 중일 때 프로그레스 바 표시
            if viewModel.isLoading {
                ProgressView("추억을 그룹화하는 중...")
                    .padding()
            }
            
            // 선택된 모드에 따라 다른 리스트 뷰를 표시
            if viewModel.viewMode == .moments {
                MomentsListView(moments: $viewModel.momentsForSelectedDate)
            } else {
                TripsListView(albums: viewModel.allAlbums)
            }
        }
        .frame(height: UIScreen.main.bounds.height - minDrawerOffset) // 드로어의 전체 높이
        .background(.black.opacity(0.8))
        .background(.ultraThinMaterial) // 뒷 배경이 비치는 블러 효과
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .white.opacity(0.15), radius: 10, y: -5)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: drawerOffset)
    }
    
    // 지도에 표시될 커스텀 핀 뷰
    private func mapPin() -> some View {
        Image(systemName: "mappin.circle.fill")
            .font(.title)
            .foregroundColor(.red)
            .background(Circle().fill(.white.opacity(0.7)))
            .shadow(radius: 3)
    }
}


#Preview {
    StudioView()
        .preferredColorScheme(.dark)
}

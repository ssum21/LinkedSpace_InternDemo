// [7] ImageSearchView.swift

import SwiftUI

struct ImageSearchView: View {
    @StateObject private var viewModel = ImageSearchViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // ▼▼▼ [수정] 뷰의 상태를 ViewModel이 참조하는 중앙 서비스(photoService)에 따라 표시합니다. ▼▼▼
                if !viewModel.photoService.isReady {
                    Spacer()
                    if viewModel.photoService.isLoading {
                        ProgressView(value: viewModel.photoService.progress, total: 1.0) {
                            Text(viewModel.photoService.statusMessage)
                        }
                        .padding()
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(viewModel.photoService.statusMessage)
                    }
                    Spacer()
                    // 수동으로 분석을 시작하는 버튼 (선택사항)
                    Button(action: { Task { await viewModel.preparePhotos() } }) {
                        Text("사진 라이브러리 분석 시작")
                    }
                    .disabled(viewModel.photoService.isLoading)
                    .padding()
                } else {
                    if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                        ContentUnavailableView.search
                    } else {
                        SearchResultsGrid(results: viewModel.searchResults)
                    }
                }
            }
            .navigationTitle("시맨틱 이미지 검색")
            .searchable(text: $viewModel.searchQuery, prompt: "예: '노을 지는 바다', '자는 고양이'")
            .onChange(of: viewModel.searchQuery) {
                Task { await viewModel.performSearch() }
            }
            .task {
                // 뷰가 나타날 때 자동으로 사진 분석을 시작 (이미 완료되었으면 실행 안 함)
                await PhotoProcessingService.shared.processInitialPhotos()
            }
            // ▲▲▲ [수정] 여기까지 ▲▲▲
        }
    }
}

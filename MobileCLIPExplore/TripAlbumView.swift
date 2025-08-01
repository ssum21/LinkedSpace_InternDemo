//
//  TripEditorView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/17/25.
//

import SwiftUI

struct TripAlbumView: View {
    @State var album: TripAlbum
    @Environment(\.dismiss) var dismiss
    @State private var isEditingTitle = false


    var body: some View {
        NavigationStack {
            List($album.days) { $day in
                NavigationLink(destination: DayDetailView(day: $day)) {
                    HStack(spacing: 15) {
                        PhotoAssetView(identifier: day.coverImage)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .clipped()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.date)
                                .font(.headline)
                            Text(day.summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text("Visiting \(day.moments.count)Place")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .navigationTitle(album.albumTitle)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isEditingTitle {
                        // 편집 모드일 때 TextField를 보여줍니다.
                        TextField("앨범 제목", text: $album.albumTitle)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                // Enter를 누르면 편집 모드 종료
                                withAnimation {
                                    isEditingTitle = false
                                }
                            }
                    } else {
                        // 평상시에는 제목을 Text로 보여주고, 탭하면 편집 모드로 전환합니다.
                        Text(album.albumTitle)
                            .font(.headline)
                            .onTapGesture {
                                withAnimation {
                                    isEditingTitle = true
                                }
                            }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

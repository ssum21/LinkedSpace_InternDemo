//
//  MomentsListView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//


import SwiftUI

struct MomentsListView: View {
    // StudioViewModel로부터 전달받는 모먼트 데이터 배열
    @Binding var moments: [Moment]
    var body: some View {
        // 데이터가 비어있을 경우와 아닌 경우를 분기하여 처리
        if moments.isEmpty {
            // MARK: - Empty State View
            VStack {
                Spacer()
                Image(systemName: "sparkles.square.filled.on.square")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("No Moments Found")
                    .font(.headline)
                    .padding(.top, 10)
                Text("There are no moments recorded for the selected day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // MARK: - Moments List
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach($moments) { $moment in
                        // 상세 뷰로 이동하기 위한 네비게이션 링크
                        NavigationLink(destination: MomentDetailView(moment: $moment)) {
                            MomentCardView(moment: $moment)
                        }
                        .buttonStyle(PlainButtonStyle()) // 링크 전체가 버튼처럼 보이는 효과 제거
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Reusable Moment Card UI (피그마 디자인 적용)

struct MomentCardView: View {
    @Binding var moment: Moment
    @State private var showingCaptionEditor = false
    @State private var showingVoiceMemo = false


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 대표 이미지
            PhotoAssetView(identifier: moment.representativeAssetId)
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()
            
            // 2. 콘텐츠 영역 (텍스트 및 버튼)
            VStack(alignment: .leading, spacing: 12) {
                // 장소 이름과 시간
                HStack {
                    VStack(alignment: .leading) {
                        Text(moment.name)
                            .font(.system(size: 18, weight: .bold))
                            .lineLimit(1)
                        Text(moment.time)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                
                // Voice / Caption 버튼
                HStack(spacing: 12) {
                    Spacer()
                    Button(action: { showingVoiceMemo = true }) {
                        Label("Voice", systemImage: "waveform")
                    }
                    .buttonStyle(MomentActionButtonStyle(hasContent: moment.voiceMemoPath != nil))
                    
                    Button(action: { showingCaptionEditor = true }) {
                        Label("Caption", systemImage: "pencil.and.ellipsis.rectangle")
                    }
                    .buttonStyle(MomentActionButtonStyle(hasContent: moment.caption != nil && !moment.caption!.isEmpty))
                }
            }
            .padding()
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.12)) // 카드 배경색
        .cornerRadius(12)
        .foregroundColor(.white)
        .sheet(isPresented: $showingCaptionEditor) {
            CaptionEditorView(moment: $moment)
        }
        .sheet(isPresented: $showingVoiceMemo) {
            VoiceMemoView(moment: $moment)
        }

    }
}


// MARK: - Custom Button Style for Voice/Caption

struct MomentActionButtonStyle: ButtonStyle {
    var hasContent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                // 콘텐츠 유무에 따라 배경 투명도 조절
                (hasContent ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .cornerRadius(20)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


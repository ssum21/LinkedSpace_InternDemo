//
//  CaptionEditorView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

import SwiftUI

struct CaptionEditorView: View {
    @Binding var moment: Moment
    @Environment(\.dismiss) private var dismiss
    
    // 뷰 내에서만 사용할 임시 캡션 텍스트
    @State private var captionText: String

    init(moment: Binding<Moment>) {
        self._moment = moment
        // 뷰가 초기화될 때 moment의 캡션을 State 변수로 복사
        self._captionText = State(initialValue: moment.wrappedValue.caption ?? "")
    }

    var body: some View {
        NavigationView {
            VStack {
                PhotoAssetView(identifier: moment.representativeAssetId)
                    .aspectRatio(4/3, contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(12)
                    .padding()

                TextEditor(text: $captionText)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                    .onAppear {
                        // 키보드가 나타날 때 텍스트 에디터에 포커스
                        UITextView.appearance().backgroundColor = .clear
                    }

                Spacer()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Edit Caption")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // 저장 버튼을 누르면 State 변수의 텍스트를 moment에 반영
                        moment.caption = captionText
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

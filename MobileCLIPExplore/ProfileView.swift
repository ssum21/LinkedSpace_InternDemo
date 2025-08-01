//
//  ProfileView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

// ProfileView.swift

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Profile Header
                    VStack {
                        Image("avatar-placeholder") // 임시 아바타 이미지 (프로젝트에 추가 필요)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(.bottom, 8)
                        
                        Text("YBStheCLIQ")
                            .font(.title.bold())
                        
                        Text("@Yoobin")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Welcome to the world of YBS. Leverage my photos to build a digital map.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 5)
                        
                        HStack(spacing: 16) {
                            Button("Interact With Avatar") {}
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            Button("Edit Profile") {}
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                    
                    // MARK: - Highlights Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Highlights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // TODO: 실제 하이라이트 데이터를 받아와서 표시해야 합니다.
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                HighlightCircleView(title: "ViewPoints", imageName: "photo.stack")
                                HighlightCircleView(title: "Best Rest...", imageName: "fork.knife")
                                HighlightCircleView(title: "Secret Spots", imageName: "eye.slash.fill")
                                HighlightCircleView(title: "Create", imageName: "plus", isCreateButton: true)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // MARK: - Nearby Places Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Nearby Places")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        // TODO: 실제 주변 장소 데이터를 받아와서 표시해야 합니다.
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                NearbyPlaceCardView(imageName: "boba-placeholder", title: "Boba Bliss", location: "San Jose, CA")
                                NearbyPlaceCardView(imageName: "sushi-placeholder", title: "Sushi Ichimoto", location: "Campbell, CA")
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .foregroundColor(.white)
            .navigationTitle("LinkedSpaces")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) { Image(systemName: "tv.and.hifispeaker.fill") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) { Image(systemName: "line.3.horizontal") }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - ProfileView Subviews

struct HighlightCircleView: View {
    let title: String
    let imageName: String
    var isCreateButton: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(isCreateButton ? Color.white.opacity(0.1) : Color.gray.opacity(0.3))
                    .frame(width: 65, height: 65)
                
                if isCreateButton {
                    Circle().stroke(Color.white, lineWidth: 1)
                }
                
                Image(systemName: imageName)
                    .font(isCreateButton ? .title : .title2)
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NearbyPlaceCardView: View {
    let imageName: String
    let title: String
    let location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(imageName) // 임시 이미지 (프로젝트에 추가 필요)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 164, height: 164)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
                .clipped()
            
            Text(title)
                .font(.caption.bold())
            
            Text(location)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 164)
    }
}


#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}

//
//  TripsListView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

import SwiftUI

struct TripsListView: View {
    // StudioViewModel로부터 전달받는 앨범(여행) 데이터 배열
    let albums: [TripAlbum]

    var body: some View {
        // 데이터가 비어있을 경우와 아닌 경우를 분기하여 처리
        if albums.isEmpty {
            // MARK: - Empty State View
            VStack {
                Spacer()
                Image(systemName: "road.lanes.curved.right")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("No Trips Found")
                    .font(.headline)
                    .padding(.top, 10)
                Text("Create your first memory trip from your photos!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // MARK: - Trips List
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(albums) { album in
                        // TripCardView를 사용하여 각 여행을 표시
                        TripCardView(album: album)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Reusable Trip Card UI (피그마 디자인 적용)

struct TripCardView: View {
    let album: TripAlbum
    
    // 앨범에 포함된 총 장소(모먼트)의 개수를 계산
    private var placeCount: Int {
        album.days.reduce(0) { $0 + $1.moments.count }
    }
    
    // 여행 기간을 표시하기 위한 텍스트
    private var dateRangeString: String {
        guard let firstDate = album.days.first?.date, let lastDate = album.days.last?.date else {
            return "Date unknown"
        }
        if firstDate == lastDate {
            return firstDate
        }
        // 날짜 포맷을 "July 20 - 25" 와 같이 변경
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startDate = formatter.date(from: firstDate)
        let endDate = formatter.date(from: lastDate)
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"

        if let startDate = startDate, let endDate = endDate {
            let startMonth = monthFormatter.string(from: startDate)
            let startDay = dayFormatter.string(from: startDate)
            let endDay = dayFormatter.string(from: endDate)
            return "\(startMonth) \(startDay) - \(endDay)"
        }
        return "\(firstDate) - \(lastDate)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 헤더: 여행 제목, 날짜, 네비게이션 링크
            NavigationLink(destination: TripAlbumView(album: album)) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(album.albumTitle)
                            .font(.headline)
                        Text(dateRangeString)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            // 2. 대표 이미지
            PhotoAssetView(identifier: album.days.first?.coverImage ?? "")
                .frame(height: 200)
                .background(Color.gray.opacity(0.3)) // 이미지가 없을 때를 위한 배경
                .clipped()
            
            // 3. 푸터: 장소 개수, Open 버튼
            HStack {
                Label("\(placeCount) Places", systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                
                Spacer()
                
                NavigationLink(destination: TripAlbumView(album: album)) {
                    Text("Open")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                }
            }
            .padding()
        }
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
        .foregroundColor(.white)
    }
}

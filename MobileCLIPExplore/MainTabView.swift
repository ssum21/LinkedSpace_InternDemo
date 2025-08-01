//
//  MatinTabView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//
import SwiftUI

// 탭 아이템 관리를 위한 Enum
enum TabItem: String, CaseIterable, Identifiable {
    case explore, notification, studio, plan, profile
    
    // Identifiable 프로토콜을 따르기 위한 id
    var id: String { self.rawValue }

    // 각 탭에 표시될 SF Symbol 아이콘 이름
    var iconName: String {
        switch self {
        case .explore: return "safari.fill"
        case .notification: return "bell.fill"
        case .studio: return "camera.macro" // 피그마의 'Studio' 아이콘과 유사한 아이콘
        case .plan: return "map.fill"
        case .profile: return "person.fill"
        }
    }
    
    // 탭 바에 표시될 텍스트
    var title: String {
        return self.rawValue.capitalized
    }
}

struct MainTabView: View {
    // 현재 선택된 탭을 추적하는 상태 변수. 기본값은 .studio
    @State private var selectedTab: TabItem = .studio
    
    init() {
        // 커스텀 탭 바를 사용하기 위해 시스템 기본 TabBar는 완전히 숨깁니다.
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. 선택된 탭에 따라 표시될 메인 콘텐츠 뷰
            Group {
                switch selectedTab {
                case .explore:
                    // TODO: Explore 기능 구현 시 뷰 연결
                    ExploreView()
                case .notification:
                    // TODO: Notification 기능 구현 시 뷰 연결
                    Text("Notification View")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                case .studio:
                    // 핵심 기능인 StudioView를 연결합니다.
                    StudioView()
                case .plan:
                    // TODO: Plan 기능 구현 시 뷰 연결
                    Text("Plan View")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                case .profile:
                    // ProfileView (피그마의 Landing Screen)를 연결합니다.
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 2. 피그마 디자인 기반의 커스텀 탭 바
            customTabBar
        }
        .ignoresSafeArea(.all, edges: .bottom) // 탭 바가 하단 안전 영역을 무시하고 끝까지 내려가도록 설정
    }
    
    // 커스텀 탭 바 UI를 구성하는 private 뷰
    private var customTabBar: some View {
        HStack {
            ForEach(TabItem.allCases) { item in
                Button(action: {
                    // 탭 아이템을 누르면 selectedTab 상태를 변경
                    selectedTab = item
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: item.iconName)
                            .font(.system(size: 22, weight: selectedTab == item ? .bold : .regular))
                            .scaleEffect(selectedTab == item ? 1.05 : 1.0)
                        
                        Text(item.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    // 선택된 탭은 흰색, 나머지는 회색으로 표시
                    .foregroundColor(selectedTab == item ? .white : .gray)
                    .frame(maxWidth: .infinity)
                }
                // 탭 전환 시 부드러운 애니메이션 효과 적용
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 30) // 하단 홈 인디케이터를 위한 여백
        .background(.black.opacity(0.95)) // 반투명 검정 배경
        .background(.ultraThinMaterial) // 블러 효과 추가
        .cornerRadius(35, corners: [.topLeft, .topRight]) // 상단 모서리만 둥글게 처리
        .shadow(color: .white.opacity(0.1), radius: 5, y: -5)
    }
}

// 특정 모서리만 둥글게 처리하기 위한 View 확장 (선택사항이지만 권장)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}

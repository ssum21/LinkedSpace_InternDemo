import Foundation

// 우리 앱에서 사용할 표준 카테고리 enum
enum AppCategory: String, CaseIterable {
    case foods = "Foods"
    case restaurants = "Restaurants"
    case coffee = "Coffee"
    case bakery = "Bakery"
    case bar = "Bar"
    case hotelsResort = "Hotels/Resort"
    case lodging = "Lodging"
    case shopping = "Shopping"
    case attractions = "Attractions"
    case sightseeing = "Sightseeing"
    case activity = "Activity"
    case golf = "Golf"
    case airport = "Airport"
    case grocery = "Grocery"
    case transportation = "Transportation"
    case park = "Park"
    
    // UI에 표시될 이름
    var displayName: String {
        return self.rawValue
    }
    
    // [에러 해결] 각 카테고리에 맞는 SF Symbol 아이콘 이름. ContentView에서 이 속성을 사용합니다.
    var iconName: String {
        switch self {
        case .foods, .restaurants, .bakery, .bar: return "fork.knife"
        case .coffee: return "cup.and.saucer.fill"
        case .hotelsResort, .lodging: return "bed.double.fill"
        case .shopping, .grocery: return "cart.fill"
        case .attractions: return "sparkles"
        case .sightseeing: return "camera.fill"
        case .activity: return "figure.walk"
        case .golf: return "flag.fill"
        case .airport: return "airplane"
        case .transportation: return "car.fill"
        case .park: return "leaf.fill"
        }
    }
}

import Foundation

struct CategoryMapper {
    
    // 1. 가독성과 확장성을 위해 딕셔너리 기반의 매핑 테이블을 사용합니다.
    private static let googleToAppCategoryMap: [String: [AppCategory]] = [
        // 음식 및 음료
        "restaurant": [.restaurants, .foods],
        "meal_delivery": [.restaurants, .foods],
        "meal_takeaway": [.restaurants, .foods],
        "food": [.foods],
        "cafe": [.coffee, .foods],
        "coffee_shop": [.coffee, .foods],
        "bakery": [.bakery, .foods, .shopping],
        "bar": [.bar],
        "night_club": [.bar],
        "liquor_store": [.shopping],

        // 숙박
        "lodging": [.lodging],
        "hotel": [.lodging, .hotelsResort],
        "motel": [.lodging],
        "resort": [.lodging, .hotelsResort], // 'resort' 유형 추가
        "spa": [.activity, .hotelsResort],   // 'spa' 유형 추가

        // 쇼핑
        "store": [.shopping],
        "shopping_mall": [.shopping],
        "department_store": [.shopping],
        "clothing_store": [.shopping],
        "shoe_store": [.shopping],
        "jewelry_store": [.shopping],
        "electronics_store": [.shopping],
        "book_store": [.shopping],
        "convenience_store": [.shopping, .grocery],
        "home_goods_store": [.shopping],
        "furniture_store": [.shopping],
        "hardware_store": [.shopping],
        "pet_store": [.shopping],
        "florist": [.shopping],
        "grocery_or_supermarket": [.grocery, .shopping],

        // 관광 및 활동
        "tourist_attraction": [.attractions, .sightseeing],
        "point_of_interest": [.attractions, .sightseeing], // 가장 일반적인 유형
        "landmark": [.attractions, .sightseeing],
        "museum": [.attractions, .sightseeing, .activity],
        "art_gallery": [.attractions, .sightseeing, .activity],
        "church": [.attractions, .sightseeing],
        "hindu_temple": [.attractions, .sightseeing],
        "mosque": [.attractions, .sightseeing],
        "synagogue": [.attractions, .sightseeing],
        "amusement_park": [.attractions, .activity],
        "aquarium": [.attractions, .activity],
        "zoo": [.attractions, .activity],
        "park": [.park, .sightseeing, .activity],
        "national_park": [.park, .sightseeing],
        "stadium": [.attractions, .activity], // 'stadium' 유형 추가
        "movie_theater": [.activity],       // 'movie_theater' 유형 추가
        "bowling_alley": [.activity],       // 'bowling_alley' 유형 추가
        "casino": [.activity, .attractions], // 'casino' 유형 추가
        "gym": [.activity],                 // 'gym' 유형 추가
        "golf_course": [.golf, .activity],
        
        // 교통
        "airport": [.airport, .transportation],
        "train_station": [.transportation],
        "subway_station": [.transportation],
        "bus_station": [.transportation],
        "light_rail_station": [.transportation],
        "transit_station": [.transportation],
        "gas_station": [.transportation],      // 'gas_station' 유형 추가
        "car_rental": [.transportation],       // 'car_rental' 유형 추가
        "parking": [.transportation],          // 'parking' 유형 추가
        
        // 기타 주요 장소
        "bank": [.attractions],
        "atm": [.attractions],
        "hospital": [.attractions],
        "doctor": [.attractions],
        "pharmacy": [.shopping],
        "post_office": [.attractions],
        "library": [.sightseeing, .attractions],
        "university": [.sightseeing, .attractions],
        "school": [.sightseeing],
        "city_hall": [.sightseeing, .attractions]
    ]

    /// Google Places API의 카테고리 배열을 우리 앱의 표준 카테고리 배열로 변환합니다.
    static func map(googleTypes: [String]) -> [AppCategory] {
        var mappedCategories = Set<AppCategory>()

        // 2. 딕셔너리를 순회하며 효율적으로 카테고리를 추가합니다.
        for type in googleTypes {
            if let appCategories = googleToAppCategoryMap[type] {
                for category in appCategories {
                    mappedCategories.insert(category)
                }
            }
        }
        
        // 3. 지능적인 폴백(Fallback) 로직
        // 만약 위에서 직접 매핑된 카테고리가 하나도 없다면,
        // 보다 일반적인 유형을 기반으로 최소한의 카테고리를 부여합니다.
        if mappedCategories.isEmpty {
            if googleTypes.contains("point_of_interest") || googleTypes.contains("establishment") {
                // 'point_of_interest' 또는 'establishment'는 모든 장소의 기본 유형이므로,
                // 이를 '관광명소'로 간주하여 분석 기회를 제공합니다.
                mappedCategories.insert(.attractions)
            }
        }
        
        // 4. 최종 폴백 로직
        // 만약 모든 노력에도 불구하고 카테고리가 비어있다면,
        // 분석에서 제외되지 않도록 기본값을 반드시 반환합니다.
        if mappedCategories.isEmpty {
            return [.attractions] // CLIP 점수 계산 기회를 잃지 않도록 보장
        }
        
        return Array(mappedCategories)
    }
}

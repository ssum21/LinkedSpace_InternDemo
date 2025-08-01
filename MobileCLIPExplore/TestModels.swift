//
//  TestModels.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/15/25.
//

import Foundation
import CoreLocation


struct TestDataSet: Codable {
    let username: String
    let analysisDate: String
    let totalPlaces: Int
    let places: [TestPlace]
}

struct TestPlace: Codable, Hashable {
    let placeName: String
    let categories: [String]
    let selectedIndex: Int
    let distance: Int
    let cloudPhotos: [TestPhoto]
    let placeIndex: Int
    let location: TestLocation
    
    // Hashable 프로토콜을 준수하기 위해 placeIndex를 사용
    func hash(into hasher: inout Hasher) {
        hasher.combine(placeIndex)
    }
    
    static func == (lhs: TestPlace, rhs: TestPlace) -> Bool {
        return lhs.placeIndex == rhs.placeIndex
    }
}

struct TestPhoto: Codable {
    let uri: String
}

struct TestLocation: Codable {
    let longitude: Double
    let latitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

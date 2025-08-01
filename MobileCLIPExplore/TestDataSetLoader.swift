//
//   TestDataSetLoader.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/15/25.
//

import Foundation

class TestDataSetLoader {
    /// JSON 파일 이름으로 테스트 데이터셋을 로드하고 파싱합니다.
    static func load(from filename: String) -> TestDataSet? {
        // 1. 파일 확장자가 있는지 확인하고, 없다면 .json을 추가합니다.
        let fullFilename = filename.hasSuffix(".json") ? filename : "\(filename).json"
        
        // 2. 앱 번들에서 파일 URL을 찾습니다.
        guard let fileUrl = Bundle.main.url(forResource: fullFilename.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            print("Error: \(fullFilename) not found in bundle.")
            return nil
        }
        
        // 3. 파일 데이터를 읽습니다.
        do {
            let data = try Data(contentsOf: fileUrl)
            // 4. JSON 디코더를 사용해 TestDataSet 구조체로 파싱합니다.
            let testDataSet = try JSONDecoder().decode(TestDataSet.self, from: data)
            return testDataSet
        } catch {
            print("Error loading or decoding \(fullFilename): \(error)")
            return nil
        }
    }
}

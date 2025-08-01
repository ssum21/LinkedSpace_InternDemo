//
// For licensing see accompanying LICENSE file.
// Copyright (C) 2024 Apple Inc. All Rights Reserved.
//

import Foundation

public let presets = [
    // 1. 동물원 및 야생동물 분석용 프리셋
    PromptPreset(
        title: "Zoo & Wildlife",
        prompt: .init(
            prefix: "A photo of a",
            suffix: "in the wild or a zoo",
            classNames: [
                // 대형 포유류
                "lion", "tiger", "elephant", "giraffe", "zebra", "monkey", "gorilla",
                "bear", "hippopotamus", "rhinoceros", "kangaroo", "panda", "camel",

                // 중소형 포유류
                "wolf", "fox", "koala", "meerkat", "red panda", "lemur", "sloth",

                // 조류
                "peacock", "flamingo", "parrot", "ostrich", "penguin", "eagle", "toucan",

                // 파충류 & 양서류
                "crocodile", "alligator", "snake", "turtle", "lizard",

                // 해양 동물
                "seal", "sea lion", "dolphin",

                // 환경 요소
                "person", "child", "family", "zookeeper", "fence", "enclosure",
                "rock formation", "waterfall", "pond", "tree"
            ])
    ),

    // 2. 여행지 풍경 및 사물 분석용 프리셋
    PromptPreset(
        title: "Travel & Scenery",
        prompt: .init(
            prefix: "A photo of a",
            suffix: "at a travel destination",
            classNames: [
                // 자연 풍경
                "beach", "ocean", "mountain", "forest", "lake", "river", "desert",
                "canyon", "volcano", "glacier", "flower field", "sunset", "sunrise",

                // 도시 및 건축물
                "cityscape", "skyscraper", "bridge", "castle", "palace", "temple",
                "cathedral", "ruins", "historic building", "market", "cafe", "harbor",

                // 음식 및 활동
                "local food", "street food", "person eating", "festival", "parade",
                "monument", "statue", "artwork",

                // 교통수단 및 기타
                "boat", "airplane", "train", "ancient architecture", "cobblestone street"
            ])
    ),
    
    // 3. 기존 Custom 프리셋 (유지)
    PromptPreset(
        title: "Custom",
        prompt: .init(
            prefix: "A photo of",
            suffix: "",
            classNames: [])
    )
]

public struct PromptPreset: Identifiable {
    public let id = UUID()
    public let title: String
    public let prompt: Prompt
}

public struct Prompt {
    public var prefix: String
    public var suffix: String
    public var classNames: [String]

    public func fullPrompts() -> [String] {
        classNames.map {
            "\(prefix) \($0) \($0.count > 0 ? suffix : "")"
        }.map { $0.trimmingCharacters(in: .whitespaces) }
    }

}

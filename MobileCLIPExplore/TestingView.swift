//
//  TestingView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/30/25.
//

// TestingView.swift

import SwiftUI

struct TestingView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Smart POI Tools")) {
                    NavigationLink(destination: SmartPOIAnalystView()) {
                        Label("Smart POI Analyzer", systemImage: "magnifyingglass.circle.fill")
                    }
                }

                Section(header: Text("Development & Accuracy")) {
                    NavigationLink(destination: AccuracyTestView()) {
                        Label("Accuracy Test", systemImage: "chart.bar.xaxis")
                    }
                }
            }
            .navigationTitle("Testing Tools")
        }
    }
}

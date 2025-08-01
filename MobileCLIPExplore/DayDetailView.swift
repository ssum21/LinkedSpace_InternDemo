//
//  DayDetailView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/17/25.
//

import SwiftUI

// MARK: - DayDetailView
/// A view that displays the details of a single day within a trip.
/// It shows a visual summary of the day and a list of all the "Moments" that occurred.
struct DayDetailView: View {

    // The `Day` model object containing all the data for this view.
    @Binding var day: Day

    // MARK: - Body
    var body: some View {
        // Use a List for a structured, scrollable layout.
        List {
            
            // MARK: - Header Section
            // This section provides a visual summary of the day.
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Display the main cover image for the day.
                    PhotoAssetView(identifier: day.coverImage)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Display the auto-generated summary text for the day's activities.
                    Text(day.summary)
                        .font(.headline)
                        .padding(.top, 4)
                }
                .padding(.vertical)
            }
            
            // MARK: - Moments List Section
            // This section lists all the individual moments (e.g., places visited) from the day.
            Section(header: Text("Today's Moments")) {
                // Iterate through each Moment in the day's data array.
                ForEach($day.moments) { $moment in
                    NavigationLink(destination: MomentDetailView(moment: $moment)) {
                        HStack(spacing: 15) {
                            // Show a representative thumbnail image for the Moment.
                            PhotoAssetView(identifier: moment.representativeAssetId)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .clipped()
                            
                            // Display textual details for the Moment.
                            VStack(alignment: .leading) {
                                // The name of the Moment (e.g., "Lotte World Tower").
                                Text(moment.name)
                                    .fontWeight(.semibold)
                                
                                // The total number of photos within this Moment.
                                Text("\(moment.allAssetIds.count) photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // The start time of the Moment.
                            Text(moment.time)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(day.date) // Set the navigation bar title to the date.
        .onAppear {
            day.summary = day.moments.map { $0.name }.prefix(3).joined(separator: ", ") + " & more"
        }
    }
}

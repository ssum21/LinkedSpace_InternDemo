//
//  PhotoAssetView.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/17/25.
//

import SwiftUI
import Photos

struct PhotoAssetView: View {
    let identifier: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            }
        }
        .onAppear(perform: loadImage)
    }

    private func loadImage() {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 400, height: 400), contentMode: .aspectFill, options: options) { loadedImage, _ in
            self.image = loadedImage
        }
    }
}

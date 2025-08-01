# 🚀 MobileCLIPExplore: LinkedSpace On-Device AI Prototype

**Notice:** This project is proprietary to LinkedSpace and is intended for internal testing and development purposes only. It is not open source. Unauthorized distribution or use is strictly prohibited.

This project was developed as part of the **KHU-2025-Internship Program (Kyung Hee University Silicon Valley Internship)**.

---

## 🌟 About This Project

**MobileCLIPExplore** is an internal R&D prototype designed to build and validate next-generation on-device AI features for the **LinkedSpace** platform. The core objective is to transform a user's photo library into a personal "Digital Twin," where all data processing, semantic analysis, and AI inference occur entirely on the user's device, ensuring maximum privacy and security.

This prototype serves as a testbed for the following key technologies:

*   **🧠 Semantic Photo Analysis**: Utilizes Apple's MobileCLIP model to convert the visual and semantic content of photos into vector embeddings.
*   **🗺️ Automated Memory Generation**: Leverages time, location, and semantic information to automatically cluster the user's daily life into meaningful "Trips" and "Moments."
*   **🤖 On-Device LLM Agent**: Implements a personalized AI agent using Google's MediaPipe framework and the Gemma family of models. This agent answers natural language queries based on the context derived from the user's photo data.
*   **⚡ Background Synchronization**: Employs iOS BackgroundTasks to incrementally process new photos, ensuring the local database is always up-to-date without requiring user interaction.

<br>

## 🏛️ Architecture Overview

The project is built on a modular, MVVM-inspired architecture designed for scalability and clear separation of concerns.

#### Core Components:

1.  **Persistence Layer (Core Data)**
    *   **`PhotoAssetCache.xcdatamodeld`**: Defines the database schema for permanently storing photo metadata and their computed image embeddings.
    *   **`PersistenceController.swift`**: A singleton helper class for managing the Core Data stack.

2.  **Photo Processing & Sync Engine**
    *   **`PhotoProcessingService.swift`**: The central engine of the application. It scans the photo library, filters for new assets by comparing against the Core Data cache, uses `ZSImageClassification` (MobileCLIP) to generate embeddings, and saves the results to the database. It also manages background sync tasks via the `BackgroundTasks` framework.
    *   **`AlbumCreationService.swift`**: Responsible for the logic of organizing the cached photo data into "Trips" and "Moments," resulting in the creation of `TripAlbum` objects.

3.  **On-Device LLM Engine**
    *   **`LlamaService.swift`**: A service layer that encapsulates the MediaPipe `LlmInference` task. It is responsible for loading the Gemma model and providing a simple interface for generating streaming text responses.
    *   **`ExploreViewModel.swift`**: The ViewModel for the chat interface. It acts as a mediator, fetching photo context from `PhotoProcessingService`, formatting it for the LLM, and passing user queries to `LlamaService`.

4.  **User Interface (SwiftUI)**
    *   **`MainTabView.swift`**: The root view that contains the main tab-based navigation (`Profile`, `Studio`, `Explore`).
    *   **`StudioView.swift`**: The primary screen that displays generated "Trips" and "Moments," featuring a map-based UI.
    *   **`ExploreView.swift`**: The conversational interface for interacting with the on-device AI agent.

<br>

## 🛠️ Getting Started

### Prerequisites

*   macOS running on Apple Silicon.
*   Xcode 16.0 or later.
*   An iOS 18.0+ simulator or a physical device.
*   CocoaPods (`sudo gem install cocoapods`).
*   A valid Apple Developer account for signing.

### Installation and Setup

1.  **Clone the Repository**:
    Access to this repository is restricted. Clone it using your company-provided credentials.

2.  **Configure API Keys**:
    *   Obtain a Google Maps API key with the **Places API** enabled from the Google Cloud Platform console.
    *   In Xcode, navigate to the `MobileCLIPExplore/Configuration/` directory.
    *   Create a new file named `Keys.xcconfig`.
    *   Add the following line to the new file, replacing `YOUR_GOOGLE_API_KEY` with your actual key:
        ```
        GOOGLE_API_KEY = YOUR_GOOGLE_API_KEY
        ```
    > **Security Note:** The `Keys.xcconfig` file is included in the project's `.gitignore` and must not be committed to the repository.

3.  **Download the LLM Model**:
    *   Download the required `gemma-2b-it-cpu-int8.bin` model from the internally specified source (e.g., Kaggle for MediaPipe).
    *   https://huggingface.co/google/gemma-2b-it-tflite/tree/main
    *   Drag and drop the downloaded `.bin` file into the `MobileCLIPExplore` folder within the Xcode project navigator.
    *   In the dialog that appears, ensure that **"Copy items if needed"** and **"Add to targets: MobileCLIPExplore"** are both checked.

4.  **Install Dependencies**:
    *   Navigate to the project's root directory (`ios_app`) in the Terminal.
    *   Run the following command to install the MediaPipe library:
        ```bash
        pod install --repo-update
        ```

5.  **Run the Application**:
    *   **Important**: Close any open Xcode sessions. From now on, you must open the project using the **`MobileCLIPExplore.xcworkspace`** file, not the `.xcodeproj` file.
    *   Select your target device and run the application (Cmd + R).
    *   On the first launch, the app will request access to the Photo Library. Grant permission to allow the `PhotoProcessingService` to begin its initial analysis.

---

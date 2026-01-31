<div align="center">
  <h1>🏆 Resume Ranking</h1>
  <p>
    <strong>A Next-Gen Profile Management & Resume Evaluation System</strong>
  </p>
  <p>
    <a href="#about">About</a> •
    <a href="#key-features">Key Features</a> •
    <a href="#technology-stack">Tech Stack</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#license">License</a>
  </p>

  ![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=flat-square)
  ![Platform](https://img.shields.io/badge/platform-Android-green.svg?style=flat-square)
  ![License](https://img.shields.io/badge/license-MIT-purple.svg?style=flat-square)
</div>

<br />

## 📖 About
**Resume Ranking** is a cutting-edge mobile application designed to showcase a modern approach to profile management and professional networking. Built as a final project for Mobile Programming, this app integrates real-time data synchronization, a stunning "Matcha" inspired aesthetic, and advanced interactive elements to create a premium user experience.

Beyond standard profiles, users can connect with friends, manage their portfolio data, and visualize their professional identity in a unique, ranked ecosystem.

## ✨ Key Features

- **🎨 Matcha UI Design**
  - A sophisticated, nature-inspired color palette primarily using shades of matcha green.
  - Clean, minimalist aesthetic with glassmorphism effects and smooth transitions.

- **👤 Advanced Profile Management**
  - Comprehensive profile editing with form validation.
  - Real-time updates for bio, skills, and personal details.
  - 3D Resume visualization capabilities for a standout presentation.

- **🤝 Social Connectivity**
  - **Friends System**: Search and add peers to your network.
  - **Real-time Interaction**: Powered by Supabase real-time subscriptions.
  
- **📊 Ranking System**
  - Competitive visualization of resumes.
  - Dynamic sorting and categorization of profiles.

- **🔒 Secure Authentication**
  - Robust sign-up and sign-in processes.
  - Data privacy and secure session management via Supabase Auth.

## 🛠 Technology Stack

### Core Framework
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

### Backend & Database
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)

### State Management & Logic
![Provider](https://img.shields.io/badge/Provider-State_Management-7952B3?style=for-the-badge)

## 🏗 App Structure

```
lib/
├── models/          # Data models and JSON serialization
├── providers/       # State management logic
├── screens/         # UI Screens (Auth, Profile, Home, etc.)
├── services/        # API and Supabase service calls
├── theme/           # Matcha app theme and style definitions
├── widgets/         # Reusable UI components
└── main.dart        # Application entry point
```

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites
- **Flutter SDK** (Latest stable version)
- **Android Studio** or **VS Code** with Flutter extensions.

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Vince0028/Resume_Ranking.git
    cd Resume_Ranking
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Environment Setup**:
    -   Create a `.env` file in the root directory.
    -   Add your Supabase credentials:
        ```env
        SUPABASE_URL=your_supabase_url
        SUPABASE_ANON_KEY=your_supabase_anon_key
        ```

4.  **Run the App**:
    ```bash
    flutter run
    ```

---

<div align="center">
  <p>Made with 🍵 by the Resume Ranking Team</p>
</div>

# 📝 Notepad

Hey there! 👋 Welcome to **Notepad**, a simple, buttery-smooth, and local-first note-taking app built with Flutter. 

I built this app because I wanted a place to write that felt fast, clean, and completely dependable. There are no distracting feeds, no forced cloud logins, and no lag—just you and your thoughts, safely stored on your own device.

<p align="center">
  <img src="https://github.com/user-attachments/assets/ae38b96d-c7fc-4483-9815-17682fd8081e" width="250" alt="Editor Screen" style="margin: 10px;" />
  <img src="https://github.com/user-attachments/assets/edcaacdc-6a28-4dac-bdbf-854de70830cd" width="250" alt="Home Screen" style="margin: 10px;" />
  <img src="https://github.com/user-attachments/assets/7fc3c20a-3746-4ec7-b7f0-244898dba152" width="250" alt="Search screen" style="margin: 10px;" />
    <img src="https://github.com/user-attachments/assets/5dd5e2bf-fc40-44ef-adc6-37b829893977"
width="250" alt="Home screen" style="margin: 10px;" />
</p>


## 🧠 Engineering & Architecture Highlights

This project was built with a strict focus on robust software engineering principles, prioritizing maintainability, data safety, and performance.

* **Decoupled Architecture:** Strict separation of UI, Controllers, and Repositories. Business logic is completely isolated from the presentation layer.
* **$O(1)$ Data Layer:** Implemented Hive with an in-memory Map indexing strategy, guaranteeing constant-time performance for lookups and saves, regardless of scale.
* **Zero-Leak State Management:** Utilized isolated `ValueNotifier` and `ValueListenableBuilder` patterns (e.g., in the SaveIndicator) to prevent unnecessary widget rebuilds and ensure clean memory disposal.
* **Defensive Programming:** Implemented robust guard clauses, debounced autosaving, and edge-case handling (such as auto-purging completely empty notes upon disposal).
* **Automated Testing Suite:** The codebase is protected by professional-grade tests:
    * **Unit Tests:** Verifying pure business logic and state transitions in the Controllers.
    * **Widget Tests:** Proving isolated UI components render correctly under specific states.
    * **Data Integrity Tests:** Utilizing mocked, sandboxed Hive environments to mathematically prove sorting invariants and soft-delete logic.

## 🎯 Why this app is useful
=======
## ✨ Cool Things It Can Do


- **Rich-text editing:** Go crazy with bold, italics, underlines, lists, and strikethroughs.
- **Worry-free Autosave:** Your changes are saved as you type. You won't lose your work!
- **Lightning-fast Search:** Find any note instantly, with your keywords highlighted in the results.
- **Recycle Bin:** Accidentally deleted something? No worries, you can restore it from the bin.
- **Pin & Select:** Pin your most important notes to the top and use bulk-selection to manage them easily.
- **Export & Share:** Turn your notes into beautiful PDFs or HTML files, or share them directly with your friends.
- **100% Offline & Local:** Everything lives directly on your device. No internet required.

## 🎯 Why Build Another Notes App?

There are a million notes apps out there, but this project is tailored for folks who prefer:
- Writing without distractions in a super clean interface.
- Keeping their data private and local.
- Having rich text formatting without the app feeling bloated and heavy.

## 🧠 Under the Hood (For the Devs)

I didn't just want the app to look good; I wanted the codebase to be highly optimized and production-ready. Here are a few architectural highlights:

- **Controller Pattern:** Business logic is strictly decoupled from the UI. Thin presentation layers (`HomePage`, `NotePage`) delegate the heavy lifting to dedicated controllers.
- **Reactive UI:** Leverages `ListenableBuilder` and `ValueNotifier` for precise, granular widget rebuilds without relying on bloated state management libraries or unnecessary `setState()` calls.
- **O(1) Data Layer:** Uses a `Map`-backed indexing strategy over Hive's NoSQL storage, guaranteeing instantaneous $O(1)$ read/write speeds, even if you have thousands of notes.
- **Safe Async Handling:** Implements `PopScope` routing and `mounted` guard clauses to completely prevent memory leaks and background crashes during asynchronous database operations.

## 📁 Project Structure

To keep things scalable and easy to maintain, the code is cleanly separated:
- `core/` - Shared colors, constants, themes, and global configurations.
- `home/` - The main dashboard and list view.
- `note/` - The editor, rich-text toolbar, auto-save logic, and recovery flows.
- `search/` - The indexing and query UI.
- `recycle/` - The trash bin and restoration logic.

## 🚀 Want to run it locally?

Awesome! It's super easy to get up and running.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.0+)
- Dart SDK

### Installation

1. Clone the repo and install the packages:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

*(Want to run it on a specific platform? Use `flutter run -d windows` or `flutter run -d android`)*

## 🛠️ Built With

- **Flutter & Dart** - The core framework and language.
- **Hive** - Blazing fast, lightweight NoSQL local database.
- **flutter_quill** - Powering the rich-text editing experience.
- **share_plus** - For seamless native sharing.
- **Lottie** - For those beautiful, smooth empty-state animations.

## 🔮 What's Next on the Roadmap?

I'm always looking to improve the app. Here is what I am planning to add next:
- Optional cloud backup and sync
- Image and file attachments
- Tags and advanced filtering
- Markdown import/export
- Small AI helpers (like a quick summary or rewrite suggestions)

---
*Built to feel practical, polished, and lightweight. Thanks for checking it out!* 💡

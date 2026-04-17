# 📝 Notepad

Notepad is a simple, smooth, and local-first note-taking app built with Flutter. It is designed to help you write quickly, keep your notes organized, and recover your work safely if something goes wrong.

## ✨ What it can do

- Rich-text editing with bold, italics, underline, lists, links, and more
- Autosave so your changes are not lost
- Search notes with highlighted matches
- Keep deleted notes in a recycle bin so they can be restored later
- Pin important notes to the top
- Select multiple notes and act on them together
- Export notes as PDF or HTML
- Share notes easily
- Recover unsaved notes after unexpected app closure
- Work offline and save everything locally

## 🎯 Why this app is useful

This project is made for people who want a notes app that feels fast, clean, and dependable. It is especially useful if you prefer:

- writing without distractions
- keeping your notes on your own device
- rich formatting without making the app feel heavy
- a simple layout that is easy to understand

## 🧱 How it is organized

The project is split into a few clear parts:

- `core` holds shared colors, constants, storage, and theme values
- `home` shows the main notes screen
- `note` contains the editor, toolbar, save logic, and recovery flow
- `search` helps you find notes quickly
- `recycle` lets you restore or delete notes more permanently

This keeps the app easier to maintain as it grows.

## 🚀 Getting Started

### Install packages

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

If you want a specific platform:

```bash
flutter run -d windows
flutter run -d android
```

## 🛠️ Built With

- Flutter
- Dart
- Hive
- flutter_quill
- PDF export tools
- share_plus
- Lottie animations

## 🔮 What would come next

- Cloud backup and sync
- Attachments like images or files
- Tags and better filtering
- Markdown import/export
- Shared notes
- Small AI helpers like summaries or rewrite suggestions

## 💡 A quick note

This project is built to feel practical and polished, while still staying lightweight and easy to use.

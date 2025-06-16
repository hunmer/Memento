<p align="center">
  <img src="assets/icon/icon.png" width="128" alt="Memento Logo">
</p>

<h1 align="center">Memento</h1>

<p align="center">
Memento is a cross-platform personal assistant application built with Flutter, integrating chat, diary, and activity tracking features.
</p>

[简体中文](README_zh.md)

## Introduction
A multi-functional recording app collection developed with Flutter, aiming to reduce the cost of switching between different apps. The vision is to enable lifelong use, improvement and collection of personal data, using AI for data analysis and decision-making to improve life.

## Quick Start

1. Clone the project
```bash
git clone https://github.com/hunmer/Memento.git
cd Memento
```

2. Get dependencies
```bash
flutter pub get
```

3. Run the project
```bash
# Debug mode
flutter run

# Platform-specific runs
flutter run -d chrome  # Web
flutter run -d windows # Windows
flutter run -d macos   # macOS
flutter run -d linux   # Linux
```

## Building for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```


## build and release

```bash
# Copy the example config file and edit it

cp scripts/release_config.example.json scripts/release_config.json

# run build script
chmod +x scripts/build.sh
./scripts/build.sh

# run release script
chmod +x scripts/release.sh
./scripts/release.sh

```

## Feature Plugins

### Channel Chat Plugin
- Create multiple channels for self-chatting/recording like WeChat File Assistant
- Support adding markdown/images/videos/voice recordings
- @AI for contextual conversations
- Timeline view and search functionality

### AI Assistant Plugin
- Add AI assistants from different service providers for other plugins to call
- Built-in data analysis application that can analyze specified data based on prompts
- Future support for AI plugin commands and voice input to let AI assist in adding tasks/creating goals

### Diary Plugin
- Simple calendar view diary
- Support markdown format input

### Activity Recording Plugin
- Record time-based activities
- Add fields like name/tags/mood/description
- Timeline/grid display
- Data statistics

## Notes Plugin
- Infinite hierarchy note system
- Markdown support

### Item Management Plugin
- Categorized personal item management
- Upload images/prices/quantities/custom fields/sub-items/usage records
- Show last used time to avoid idle items

### Bill Plugin
- Manage multiple accounts
- Record income/expense bills
- Statistical analysis

### Calendar Plugin (To be improved)
- Display all plugin events
- Support custom events
- Multiple view modes

### Check-in Plugin
- Create multiple check-in items in different groups

### Contacts Plugin
- Manage contact info (name/phone/address/tags/custom fields)
- Record contact history
- Maintain relationships

### Timer Plugin (To be improved)
- Create multiple timers
- Support various timing methods

### Tasks Plugin
- Manage tasks/subtasks
- Support priorities/date ranges/execution timing

### Anniversary Plugin
- Record multiple anniversaries (count-up/countdown)
- Set covers/add event notes

### Goal Tracking Plugin
- Track quantifiable goals (like running distance/water intake)

### Item Exchange Plugin
- Create item exchange system
- Set points earned by completing different plugin tasks

### Node Plugin
- Create notebook system
- Organize content with node/subnode tree structure

### Diary Album Plugin
- Record daily small things by date
- Upload photos with tags

### Habit Management Plugin
- Manage multiple habits and skills
- Associate habits with skills to accumulate "10,000 hours" mastery

### Database Plugin
- Create custom databases
- Flexibly define field types
- Freely manage data

## Notes
- This software is entirely AI-written, developer only provided ideas and framework
- First attempt at Flutter app, may contain many bugs
- Developers are welcome to contribute!
- Currently in early testing phase, updates may cause data loss - please backup!
- All suggestions/ideas are welcome, reasonable ones will be added to development plan
- Constructive criticism is appreciated!


## Screenshots

| Chat | Diary | Activity |
|:----:|:-----:|:-----:|
| ![Chat](screenshots/chat_plugin.jpg) | ![Diary](screenshots/diary_plugin.jpg) | ![Activity](screenshots/activity_plugin.jpg) |

| AI | Bill | Album |
|:----:|:-----:|:-----:|
| ![AI](screenshots/ai_plugin.jpg) | ![Bill](screenshots/bill_plugin.jpg) | ![Album](screenshots/calendar_album.jpg) |

| Calendar | Checkin | Contact |
|:----:|:-----:|:-----:|
| ![Calendar](screenshots/calendar_plugin.jpg) | ![Checkin](screenshots/checkin_plugin.jpg) | ![Contact](screenshots/contact_plugin.jpg) |

| Database | Day | Diary |
|:----:|:-----:|:-----:|
| ![Database](screenshots/database_plugin.jpg) | ![Day](screenshots/day_plugin.jpg) | ![Diary](screenshots/diary_plugin.jpg) |

| Goods | Habits | Notes |
|:----:|:-----:|:-----:|
| ![Goods](screenshots/goods_plugin.jpg) | ![Habits](screenshots/habits_plugin.jpg) | ![Notes](screenshots/notes_plugin.jpg) |

| Store | Timer | Todo | Tracker |
|:----:|:-----:|:-----:|:-----:|
| ![Store](screenshots/store_plugin.jpg) | ![Timer](screenshots/timer_plugin.jpg) | ![Todo](screenshots/todo_plugin.jpg) | ![Tracker](screenshots/tracker_plugin.jpg) |

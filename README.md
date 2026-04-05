# PurgeMac

<p align="center">
  <img src="logo.png" width="80" alt="PurgeMac icon" />
</p>

<p align="center">
  A fast, modern macOS cleaner — open source alternative to CleanMyMac.
  <br/>
  <strong>Clean. Fast. Yours.</strong>
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-26%2B-black?logo=apple&logoColor=white" />
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5-orange?logo=swift&logoColor=white" />
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-✓-blue" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
</p>

---

## What is PurgeMac?

PurgeMac is a native macOS app built with SwiftUI that helps you reclaim disk space and take control of your system — without subscriptions, telemetry, or hidden costs.

It provides a curated set of tools covering the most impactful cleanup tasks a Mac user (and developer) faces daily.

---

## Features

### Dashboard

A home screen with quick-access cards to every module and an overview of available tools.

### Duplicate Finder

Scans your Home folder (or any folder you choose) for duplicate files using **SHA-256 content hashing**. Groups duplicates, auto-selects the redundant copies, and lets you trash them in one click.

### Login Items Manager

Lists all LaunchAgent and LaunchDaemon plists on your system. Properly resolves app names by reading `CFBundleDisplayName` from the `.app` bundle — not just the raw plist label. Toggle or remove startup items without opening System Settings.

### Downloads Cleaner

Reads your `~/Downloads` folder and lists every file with size, type, and date. Sort by newest, largest, or name. Select and trash in bulk.

### Storage Visualizer

Shows a live animated donut chart of your disk usage broken down by category: System, Applications, Documents, Library, Other, and Available space. Reads real volume stats from the OS.

### Developer Tools

Pick a project folder, then run targeted cleanup tasks with a single click:

| Task             | What it removes                                                 |
| ---------------- | --------------------------------------------------------------- |
| `node_modules`   | All dependency folders recursively                              |
| `.DS_Store`      | macOS metadata files                                            |
| Build artifacts  | `dist/`, `build/`, `.next/`, `out/`, `__pycache__`, `.turbo/`   |
| Lock files       | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb` |
| `.cache` folders | Babel, ESLint, Parcel, etc.                                     |
| `*.log` files    | All log files in the project tree                               |
| Coverage reports | `coverage/`, `.nyc_output/`                                     |

Each task reports how many items were removed and how many bytes were freed. The folder size is recalculated after every operation.

---

## Architecture

| Layer       | Technology                                                                |
| ----------- | ------------------------------------------------------------------------- |
| UI          | SwiftUI, `NavigationSplitView`                                            |
| State       | `@Observable` + `@MainActor` ViewModels (MVVM)                            |
| Concurrency | Swift `async/await`, `Task.detached` for background work                  |
| Hashing     | `CryptoKit` (SHA-256)                                                     |
| Sandbox     | App Sandbox enabled — `user-selected.read-write` + `downloads.read-write` |

The project uses Xcode's `PBXFileSystemSynchronizedRootGroup` — any `.swift` file added to `PurgeMac/` is automatically included in the build target.

---

## Requirements

- macOS 26 or later
- Xcode 26 or later

---

## Building

```bash
git clone https://github.com/A5TUT0/PurgeMac.git
cd PurgeMac
open PurgeMac.xcodeproj
```

Select the **PurgeMac** scheme, choose **My Mac** as the destination, and hit **Run** (`⌘R`).

> No external dependencies or package manager required — pure Swift + Apple frameworks.

---

## Privacy & Security

- **No telemetry.** PurgeMac never phones home.
- **No cloud.** Everything runs locally on your machine.
- **Sandboxed.** The app runs inside the macOS App Sandbox. It can only access files you explicitly select via the system file picker, plus your Downloads folder.

---

## License

MIT © [A5TUT0](https://github.com/A5TUT0)

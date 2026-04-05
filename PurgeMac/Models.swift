//
//  Models.swift
//  PurgeMac
//
//  All shared data models.
//

import Foundation

// MARK: - Navigation

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard  = "Dashboard"
    case duplicates = "Duplicates"
    case loginItems = "Login Items"
    case downloads  = "Downloads"
    case storage    = "Storage"
    case developer  = "Developer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard:  return "house.fill"
        case .duplicates: return "doc.on.doc.fill"
        case .loginItems: return "power.circle.fill"
        case .downloads:  return "arrow.down.to.line.circle.fill"
        case .storage:    return "internaldrive.fill"
        case .developer:  return "terminal.fill"
        }
    }

    var tagline: String {
        switch self {
        case .dashboard:  return "Overview"
        case .duplicates: return "Find & remove duplicate files"
        case .loginItems: return "Manage startup apps"
        case .downloads:  return "Clean your downloads folder"
        case .storage:    return "Visualize your disk usage"
        case .developer:  return "Dev project cleanup tools"
        }
    }
}

// MARK: - Duplicates

struct DuplicateFile: Identifiable, Hashable {
    var id = UUID()
    let url: URL
    var isSelected: Bool = false
    var size: Int64 = 0
    var dateModified: Date = Date()

    var name: String { url.lastPathComponent }
    var directory: String { url.deletingLastPathComponent().path }

    static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct DuplicateGroup: Identifiable {
    var id = UUID()
    var files: [DuplicateFile]
    var fileSize: Int64

    var potentialSavings: Int64 { fileSize * Int64(files.count - 1) }
    var displayName: String { files.first?.name ?? "Unknown" }
    var selectedCount: Int { files.filter { $0.isSelected }.count }
}

// MARK: - Login Items

struct LoginItem: Identifiable {
    var id = UUID()
    let label: String
    let displayName: String
    let executablePath: String
    var isEnabled: Bool
    var plistURL: URL?
}

// MARK: - Downloads

struct DownloadFile: Identifiable {
    var id = UUID()
    let url: URL
    var isSelected: Bool = false
    let size: Int64
    let dateAdded: Date
    let fileExtension: String

    var name: String { url.lastPathComponent }

    var typeIcon: String {
        switch fileExtension.lowercased() {
        case "pdf":                        return "doc.richtext.fill"
        case "zip","gz","tar","rar","7z":  return "archivebox.fill"
        case "jpg","jpeg","png","gif","heic","webp": return "photo.fill"
        case "mp4","mov","avi","mkv":      return "video.fill"
        case "mp3","m4a","wav","flac":     return "music.note"
        case "dmg","pkg":                  return "shippingbox.fill"
        case "xls","xlsx","csv":           return "tablecells.fill"
        case "doc","docx":                 return "doc.text.fill"
        case "ppt","pptx":                 return "rectangle.on.rectangle.fill"
        case "sketch","fig":               return "paintbrush.fill"
        default:                           return "doc.fill"
        }
    }

    var typeColor: String {
        switch fileExtension.lowercased() {
        case "pdf":                        return "EE3627"
        case "zip","gz","tar","rar","7z":  return "ca726a"
        case "jpg","jpeg","png","gif","heic","webp": return "3B9450"
        case "mp4","mov","avi","mkv":      return "4A6FA5"
        case "mp3","m4a","wav","flac":     return "9B59B6"
        case "dmg","pkg":                  return "E67E22"
        default:                           return "7F8C8D"
        }
    }
}

// MARK: - Storage

struct StorageCategory: Identifiable {
    var id = UUID()
    let name: String
    let bytes: Int64
    let colorHex: String
    let icon: String
}

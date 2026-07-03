import Foundation

struct Shortcut: Identifiable {
    let id = UUID()
    let category: String
    let command: String
    let description: String
    let variants: [String]
}

enum ShortcutCategory: String, CaseIterable {
    case mac = "MAC"
    case chrome = "CHROME"
    case ideaNav = "IDEA (Navigation)"
    case ideaEdit = "IDEA (Editing)"
    case ideaRun = "IDEA (Search & Run)"
}

let shortcutsData: [Shortcut] = [
    // MODULE 1 — macOS Essentials
    Shortcut(category: "MAC", command: "Cmd+Space", description: "Open Spotlight search", variants: ["cmd+space"]),
    Shortcut(category: "MAC", command: "Cmd+Tab", description: "Switch between open apps", variants: ["cmd+tab"]),
    Shortcut(category: "MAC", command: "Cmd+` (backtick)", description: "Switch windows of the SAME app", variants: ["cmd+`", "cmd+backtick"]),
    Shortcut(category: "MAC", command: "Cmd+Q", description: "Quit an app completely", variants: ["cmd+q"]),
    Shortcut(category: "MAC", command: "Cmd+Opt+Esc", description: "Force Quit (app is frozen)", variants: ["cmd+opt+esc", "cmd+option+esc"]),
    Shortcut(category: "MAC", command: "Cmd+H", description: "Hide current app", variants: ["cmd+h"]),
    Shortcut(category: "MAC", command: "Ctrl+Cmd+Q", description: "Lock screen", variants: ["ctrl+cmd+q", "control+cmd+q"]),
    Shortcut(category: "MAC", command: "Cmd+Shift+4", description: "Take screenshot (select area)", variants: ["cmd+shift+4"]),
    Shortcut(category: "MAC", command: "Cmd+Shift+3", description: "Take screenshot (full screen)", variants: ["cmd+shift+3"]),
    Shortcut(category: "MAC", command: "Cmd+Shift+5", description: "Screenshot toolbar (annotate/record)", variants: ["cmd+shift+5"]),
    Shortcut(category: "MAC", command: "Ctrl+Cmd+Space", description: "Open emoji picker", variants: ["ctrl+cmd+space"]),
    Shortcut(category: "MAC", command: "Ctrl+Up", description: "Mission Control (see all windows)", variants: ["ctrl+up"]),
    Shortcut(category: "MAC", command: "Cmd+Z", description: "Undo", variants: ["cmd+z"]),
    Shortcut(category: "MAC", command: "Cmd+Shift+Z", description: "Redo", variants: ["cmd+shift+z"]),
    Shortcut(category: "MAC", command: "Cmd+C / X / V", description: "Copy / Cut / Paste", variants: ["cmd+c", "cmd+x", "cmd+v"]),
    Shortcut(category: "MAC", command: "Cmd+Shift+V", description: "Paste WITHOUT formatting", variants: ["cmd+shift+v"]),

    // MODULE 2 — Chrome
    Shortcut(category: "CHROME", command: "Cmd+T", description: "Open new tab", variants: ["cmd+t"]),
    Shortcut(category: "CHROME", command: "Cmd+W", description: "Close current tab", variants: ["cmd+w"]),
    Shortcut(category: "CHROME", command: "Cmd+Shift+T", description: "Reopen last closed tab", variants: ["cmd+shift+t"]),
    Shortcut(category: "CHROME", command: "Cmd+Shift+N", description: "Open new INCOGNITO window", variants: ["cmd+shift+n"]),
    Shortcut(category: "CHROME", command: "Cmd+L", description: "Jump to ADDRESS bar", variants: ["cmd+l"]),
    Shortcut(category: "CHROME", command: "Cmd+F", description: "Find text on page", variants: ["cmd+f"]),
    Shortcut(category: "CHROME", command: "Cmd+[", description: "Go BACK in history", variants: ["cmd+["]),
    Shortcut(category: "CHROME", command: "Cmd+]", description: "Go FORWARD in history", variants: ["cmd+]"]),
    Shortcut(category: "CHROME", command: "Cmd+Shift+R", description: "Hard reload (bypass cache)", variants: ["cmd+shift+r"]),
    Shortcut(category: "CHROME", command: "Cmd+R", description: "Normal reload", variants: ["cmd+r"]),
    Shortcut(category: "CHROME", command: "Cmd+Opt+I", description: "Open DevTools", variants: ["cmd+opt+i", "cmd+option+i"]),
    Shortcut(category: "CHROME", command: "Cmd+Opt+J", description: "Open DevTools Console tab", variants: ["cmd+opt+j", "cmd+option+j"]),
    Shortcut(category: "CHROME", command: "Ctrl+Tab", description: "Jump to NEXT tab", variants: ["ctrl+tab"]),
    Shortcut(category: "CHROME", command: "Ctrl+Shift+Tab", description: "Jump to PREVIOUS tab", variants: ["ctrl+shift+tab"]),
    Shortcut(category: "CHROME", command: "Cmd+2", description: "Jump to tab by NUMBER (e.g. tab 2)", variants: ["cmd+2"]),
    Shortcut(category: "CHROME", command: "Cmd+9", description: "Jump to LAST tab", variants: ["cmd+9"]),
    Shortcut(category: "CHROME", command: "Cmd++", description: "Zoom IN", variants: ["cmd++"]),
    Shortcut(category: "CHROME", command: "Cmd+-", description: "Zoom OUT", variants: ["cmd+-"]),
    Shortcut(category: "CHROME", command: "Cmd+0", description: "Reset zoom to 100%", variants: ["cmd+0"]),
    Shortcut(category: "CHROME", command: "Cmd+D", description: "Bookmark this page", variants: ["cmd+d"]),
    Shortcut(category: "CHROME", command: "Cmd+Opt+B", description: "Open bookmark manager", variants: ["cmd+opt+b", "cmd+option+b"]),
    Shortcut(category: "CHROME", command: "Cmd+Y", description: "Open History page", variants: ["cmd+y"]),
    Shortcut(category: "CHROME", command: "Cmd+Shift+J", description: "Open Downloads page", variants: ["cmd+shift+j"]),
    Shortcut(category: "CHROME", command: "Shift+Alt+T", description: "Focus on first item in toolbar", variants: ["shift+alt+t", "shift+opt+t"]),
    Shortcut(category: "CHROME", command: "Cmd+,", description: "Open Chrome Settings", variants: ["cmd+,"]),

    // MODULE 3 — IntelliJ Navigation
    Shortcut(category: "IDEA (Navigation)", command: "Double Shift", description: "Search EVERYWHERE", variants: ["doubleshift", "shift+shift"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Shift+O", description: "Find FILE by name", variants: ["cmd+shift+o"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+O", description: "Find CLASS by name", variants: ["cmd+o"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Opt+O", description: "Find SYMBOL by name", variants: ["cmd+opt+o", "cmd+option+o"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Shift+A", description: "Find ACTION", variants: ["cmd+shift+a"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+B", description: "Go to DECLARATION", variants: ["cmd+b"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Opt+B", description: "Go to IMPLEMENTATION", variants: ["cmd+opt+b", "cmd+option+b"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Shift+B", description: "Go to TYPE definition", variants: ["cmd+shift+b"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+[", description: "Go BACK to previous location", variants: ["cmd+["]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+]", description: "Go FORWARD to next location", variants: ["cmd+]"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Shift+Delete", description: "Go to LAST edited location", variants: ["cmd+shift+delete", "cmd+shift+backspace"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+E", description: "Switch between recent FILES", variants: ["cmd+e"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+Shift+E", description: "Switch between recent CHANGED files", variants: ["cmd+shift+e"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+L", description: "Jump to LINE number", variants: ["cmd+l"]),
    Shortcut(category: "IDEA (Navigation)", command: "Ctrl+M", description: "Go to matching BRACE", variants: ["ctrl+m"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+F12", description: "Show FILE STRUCTURE", variants: ["cmd+f12"]),
    Shortcut(category: "IDEA (Navigation)", command: "Opt+F12", description: "Open TERMINAL", variants: ["opt+f12", "option+f12"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+1", description: "Show PROJECT tool window", variants: ["cmd+1"]),
    Shortcut(category: "IDEA (Navigation)", command: "Esc", description: "Focus back to EDITOR", variants: ["esc"]),
    Shortcut(category: "IDEA (Navigation)", command: "Cmd+3", description: "Open FIND tool window", variants: ["cmd+3"]),

    // MODULE 4 — IntelliJ Editing
    Shortcut(category: "IDEA (Editing)", command: "Ctrl+Space", description: "Basic code COMPLETION", variants: ["ctrl+space"]),
    Shortcut(category: "IDEA (Editing)", command: "Ctrl+Shift+Space", description: "Smart code completion", variants: ["ctrl+shift+space"]),
    Shortcut(category: "IDEA (Editing)", command: "Opt+Enter", description: "Show QUICK FIX / intention", variants: ["opt+enter", "option+enter", "alt+enter"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+P", description: "Show parameter INFO", variants: ["cmd+p"]),
    Shortcut(category: "IDEA (Editing)", command: "F1 or Ctrl+J", description: "Show DOCUMENTATION popup", variants: ["f1", "ctrl+j"]),
    Shortcut(category: "IDEA (Editing)", command: "Shift+F6", description: "RENAME symbol", variants: ["shift+f6"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Opt+M", description: "EXTRACT method", variants: ["cmd+opt+m", "cmd+option+m"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Opt+V", description: "EXTRACT variable", variants: ["cmd+opt+v", "cmd+option+v"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Opt+N", description: "INLINE variable/method", variants: ["cmd+opt+n", "cmd+option+n"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+D", description: "Duplicate current line", variants: ["cmd+d"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Delete", description: "Delete current line", variants: ["cmd+delete", "cmd+backspace"]),
    Shortcut(category: "IDEA (Editing)", command: "Shift+Opt+Up", description: "Move line UP", variants: ["shift+opt+up", "shift+option+up"]),
    Shortcut(category: "IDEA (Editing)", command: "Shift+Opt+Down", description: "Move line DOWN", variants: ["shift+opt+down", "shift+option+down"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Shift+Up", description: "Move STATEMENT up", variants: ["cmd+shift+up"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+/", description: "Comment / uncomment line", variants: ["cmd+/"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Opt+/", description: "Block comment", variants: ["cmd+opt+/", "cmd+option+/"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Opt+L", description: "Reformat code", variants: ["cmd+opt+l", "cmd+option+l"]),
    Shortcut(category: "IDEA (Editing)", command: "Ctrl+Opt+O", description: "Optimize imports", variants: ["ctrl+opt+o", "ctrl+option+o"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+N", description: "Generate code", variants: ["cmd+n"]),
    Shortcut(category: "IDEA (Editing)", command: "Cmd+Opt+T", description: "Surround with", variants: ["cmd+opt+t", "cmd+option+t"]),
    Shortcut(category: "IDEA (Editing)", command: "Opt+Up", description: "Expand code selection", variants: ["opt+up", "option+up"]),
    Shortcut(category: "IDEA (Editing)", command: "Opt+Down", description: "Shrink code selection", variants: ["opt+down", "option+down"]),

    // MODULE 5 — IntelliJ Search & Run
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+F", description: "Find text IN current file", variants: ["cmd+f"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+R", description: "Find and REPLACE in current file", variants: ["cmd+r"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+Shift+F", description: "Find in ALL files", variants: ["cmd+shift+f"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+Shift+R", description: "Replace in ALL files", variants: ["cmd+shift+r"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Opt+F7", description: "Find USAGES of symbol", variants: ["opt+f7", "option+f7"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+Shift+F7", description: "Highlight usages in file", variants: ["cmd+shift+f7"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Ctrl+R", description: "Run current configuration", variants: ["ctrl+r"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Ctrl+D", description: "Debug current configuration", variants: ["ctrl+d"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Ctrl+Opt+R", description: "Run ANY configuration", variants: ["ctrl+opt+r", "ctrl+option+r"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+F2", description: "Stop running process", variants: ["cmd+f2"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+F8", description: "Toggle BREAKPOINT", variants: ["cmd+f8"]),
    Shortcut(category: "IDEA (Search & Run)", command: "F8", description: "Step OVER", variants: ["f8"]),
    Shortcut(category: "IDEA (Search & Run)", command: "F7", description: "Step INTO", variants: ["f7"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Shift+F8", description: "Step OUT", variants: ["shift+f8"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Opt+Cmd+R", description: "Resume program", variants: ["opt+cmd+r", "option+cmd+r"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Opt+F8", description: "Evaluate expression", variants: ["opt+f8", "option+f8"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+K", description: "Open GIT commit dialog", variants: ["cmd+k"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+Shift+K", description: "Open GIT push dialog", variants: ["cmd+shift+k"]),
    Shortcut(category: "IDEA (Search & Run)", command: "Cmd+9", description: "Show GIT log", variants: ["cmd+9"])
]

import SwiftUI
import Combine

@Observable
class TrainerViewModel {
    var score: Int = 0
    var total: Int = 0
    var streak: Int = 0
    var maxStreak: Int = 0
    var startTime: Date = Date()

    var currentShortcut: Shortcut?
    var userInput: String = ""
    var capturedModifiers: NSEvent.ModifierFlags = []
    var capturedKey: String = ""

    var feedback: String?
    var isCorrect: Bool?

    var quizQueue: [Shortcut] = []
    var isSessionActive: Bool = false
    private var eventMonitor: Any?

    func startSession(category: String?) {
        let filtered = category == nil ? shortcutsData : shortcutsData.filter { $0.category == category }
        quizQueue = filtered.shuffled()
        score = 0
        total = 0
        streak = 0
        maxStreak = 0
        startTime = Date()
        isSessionActive = true
        setupKeyMonitor()
        nextQuestion()
    }

    func stopSession() {
        isSessionActive = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func setupKeyMonitor() {
        if eventMonitor != nil { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isSessionActive, self.feedback == nil else { return event }

            self.handleKeyEvent(event)
            return nil // Swallow the event so it doesn't trigger system actions during training
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags
        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

        var inputString = ""
        if modifiers.contains(.command) { inputString += "cmd+" }
        if modifiers.contains(.option) { inputString += "opt+" }
        if modifiers.contains(.shift) { inputString += "shift+" }
        if modifiers.contains(.control) { inputString += "ctrl+" }

        // Handle special keys
        let key = characters == " " ? "space" : characters
        inputString += key

        userInput = inputString
        checkAnswer()
    }

    func nextQuestion() {
        if quizQueue.isEmpty {
            stopSession()
            currentShortcut = nil
            return
        }
        currentShortcut = quizQueue.removeFirst()
        userInput = ""
        feedback = nil
        isCorrect = nil
    }

    func checkAnswer() {
        guard let current = currentShortcut else { return }

        let cleanInput = userInput.lowercased().replacingOccurrences(of: " ", with: "")
        let matched = current.variants.contains { $0.lowercased().replacingOccurrences(of: " ", with: "") == cleanInput }

        total += 1
        if matched {
            score += 1
            streak += 1
            maxStreak = max(maxStreak, streak)
            isCorrect = true
            feedback = "Correct!"
        } else {
            streak = 0
            isCorrect = false
            feedback = "Wrong. Answer: \(current.command)"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.nextQuestion()
        }
    }
}

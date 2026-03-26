import SwiftUI

// ── Difficulty ────────────────────────────────────────────────────
enum Difficulty: String, CaseIterable {
    case easy   = "Easy"
    case medium = "Medium"
    case hard   = "Hard"

    var lower: Int { 1 }

    var upper: Int {
        switch self {
        case .easy:   return 10
        case .medium: return 100
        case .hard:   return 1000
        }
    }

    var maxGuesses: Int {
        switch self {
        case .easy:   return 10
        case .medium: return 7
        case .hard:   return 5
        }
    }
}

// ── Rainbow Gradient ──────────────────────────────────────────────
var rainbowGradient: LinearGradient {
    LinearGradient(
        colors: [.red, .orange, .yellow, .green, .blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// ── Main View ─────────────────────────────────────────────────────
struct ContentView: View {

    @State private var difficulty    = Difficulty.easy
    @State private var secretNumber  = 0
    @State private var attempts      = 0
    @State private var guessText     = ""
    @State private var feedback      = "Can you guess my number?"
    @State private var feedbackColor = Color.white
    @State private var arrow         = ""
    @State private var rangeText     = "Range: 1 - 10"
    @State private var rangeColor    = Color(red: 0.39, green: 0.40, blue: 0.95)
    @State private var guessesLeft   = 10
    @State private var gameOver      = false
    @State private var shakeField    = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            Color(red: 0.118, green: 0.161, blue: 0.239)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    TitleView()
                    cardView
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear { startNewGame() }
    }

    // ── Card ──────────────────────────────────────────────────────
    var cardView: some View {
        VStack(spacing: 16) {
            difficultyPicker
            statsRow
            rangeRow
            feedbackRow
            arrowRow
            Spacer()
            guessRow
            submitButton
            playAgainButton
            hintLabel
            Spacer()
        }
        .padding(35)
        .background(Color.purple)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .frame(maxWidth: 750)          // ← caps width on iPad
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)    }

    // ── Sub-views ─────────────────────────────────────────────────

    var difficultyPicker: some View {
        Picker("Difficulty", selection: $difficulty) {
            ForEach(Difficulty.allCases, id: \.self) { level in
                Text(level.rawValue).tag(level)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 10)
        .onChange(of: difficulty) { startNewGame() }
    }

    var statsRow: some View {
        HStack(spacing: 30) {
            Text("Attempts: \(attempts)")
                .font(.system(size: 14))
                .foregroundColor(.cyan)
            Text("Guesses left: \(guessesLeft)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(guessesLeftColor)
        }
    }

    var rangeRow: some View {
        Text(rangeText)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(rangeColor)
    }

    var feedbackRow: some View {
        Text(feedback)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(feedbackColor)
            .multilineTextAlignment(.center)
            .animation(.easeIn(duration: 0.3), value: feedback)
    }

    var arrowRow: some View {
        Text(arrow)
            .font(.system(size: 60))
            .frame(height: arrow.isEmpty ? 0 : 70)
            .animation(.easeInOut, value: arrow)
    }

    var guessRow: some View {
        HStack(spacing: 10) {
            Button("-1") { adjustGuess(-1) }
                .buttonStyle(PrimaryButtonStyle(width: 55))

            TextField("Enter guess…", text: $guessText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 160, height: 50)
                .background(Color.gray)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange, lineWidth: 2)
                )
                .focused($fieldFocused)
                .disabled(gameOver)
                .opacity(gameOver ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: gameOver)
                .modifier(ShakeEffect(shake: shakeField))
                .onSubmit { processGuess() }

            Button("+1") { adjustGuess(1) }
                .buttonStyle(PrimaryButtonStyle(width: 55))
        }
    }

    var submitButton: some View {
        Button("Submit Guess") { processGuess() }
            .buttonStyle(PrimaryButtonStyle(width: 200))
            .disabled(gameOver)
    }

    var playAgainButton: some View {
        Group {
            if gameOver {
                Button("🔄  Play Again") { startNewGame() }
                    .buttonStyle(SuccessButtonStyle())
                    .transition(.scale)
            }
        }
    }

    var hintLabel: some View {
        Text("Tap Submit Guess or press return")
            .font(.system(size: 12))
            .italic()
            .foregroundColor(.orange)
    }

    // ── Computed ──────────────────────────────────────────────────

    var guessesLeftColor: Color {
        if guessesLeft <= 2 { return .red }
        if guessesLeft <= 4 { return .orange }
        return .yellow
    }

    // ── Game Logic ────────────────────────────────────────────────

    func startNewGame() {
        secretNumber  = Int.random(in: difficulty.lower...difficulty.upper)
        attempts      = 0
        guessesLeft   = difficulty.maxGuesses
        guessText     = ""
        feedback      = "Can you guess my number?"
        feedbackColor = .white
        arrow         = ""
        rangeText     = "Range: \(difficulty.lower) - \(difficulty.upper)"
        rangeColor    = Color(red: 0.39, green: 0.40, blue: 0.95)
        gameOver      = false
        fieldFocused  = true
    }

    func adjustGuess(_ delta: Int) {
        let current  = Int(guessText) ?? 0
        let adjusted = min(difficulty.upper, max(difficulty.lower, current + delta))
        guessText    = String(adjusted)
        fieldFocused = true
    }

    func processGuess() {
        guard let guess = Int(guessText) else {
            feedback      = "⚠️ Please enter a valid number!"
            feedbackColor = .yellow
            triggerShake()
            return
        }
        guard guess >= difficulty.lower && guess <= difficulty.upper else {
            feedback      = "⚠️ Must be between \(difficulty.lower) and \(difficulty.upper)!"
            feedbackColor = .red
            triggerShake()
            return
        }

        attempts    += 1
        guessesLeft -= 1

        if guess < secretNumber {
            feedback      = "📉 Too Low! Try higher."
            feedbackColor = .red
            arrow         = "⬆"
            rangeText     = "Range: \(difficulty.lower) — \(difficulty.upper)"
            rangeColor    = .red
           // guessText     = ""
            fieldFocused  = true
        } else if guess > secretNumber {
            feedback      = "📈 Too High! Try lower."
            feedbackColor = .orange
            arrow         = "⬇"
            rangeText     = "Range: \(difficulty.lower) — \(difficulty.upper)"
            rangeColor    = .orange
           // guessText     = ""
            fieldFocused  = true
        } else {
            feedback      = "🎉 Correct! It was \(secretNumber)!"
            feedbackColor = .green
            arrow         = "🎯"
            rangeText     = "Solved in \(attempts) \(attempts == 1 ? "try!" : "tries!")"
            rangeColor    = .green
            gameOver      = true
            return
        }

        if guessesLeft <= 0 {
            feedback      = "💀 Out of guesses! It was \(secretNumber)."
            feedbackColor = .red
            arrow         = "❌"
            gameOver      = true
        }
    }

    func triggerShake() {
        shakeField = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeField = false
        }
    }
}

// ── Title Sub-view ────────────────────────────────────────────────
struct TitleView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome to the\nDaddy Circus Guessing\n Game")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(rainbowGradient)

            Text("I'm thinking of a number...")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(rainbowGradient)
        }
        .padding(.top, 20)
    }
}

// ── Button Styles ─────────────────────────────────────────────────
struct PrimaryButtonStyle: ButtonStyle {
    var width: CGFloat = 200

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: width, height: 45)
            .background(configuration.isPressed ? Color.green.opacity(0.7) : Color.green)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SuccessButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.green)
            .frame(width: 200, height: 45)
            .background(configuration.isPressed ? Color.yellow.opacity(0.7) : Color.yellow)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// ── Shake Animation ───────────────────────────────────────────────
struct ShakeEffect: ViewModifier {
    var shake: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: shake ? 8 : 0)
            .animation(
                shake
                    ? .easeInOut(duration: 0.07).repeatCount(4, autoreverses: true)
                    : .default,
                value: shake
            )
    }
}

// ── Preview ───────────────────────────────────────────────────────
#Preview {
    ContentView()
}

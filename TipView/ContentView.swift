import SwiftUI

struct ContentView: View {
    @State private var amount: String = ""
    @State private var tipPercent: Double = 15
    
    // Split quote into text + author
    @State private var randomQuoteText: String = ""
    @State private var randomQuoteAuthor: String = ""

    @State private var history: [String] = []  // Save calculation history

    // Quotes split into (text, author)
    let quotes: [(text: String, author: String)] = [
        ("It is better to be alone than in bad company.", "George Washington"),
        ("The only true wisdom is in knowing you know nothing.", "Socrates"),
        ("Life is like riding a bicycle. To keep your balance, you must keep moving.", "Albert Einstein"),
        ("I have a dream.", "Martin Luther King Jr."),
        ("Whatever you are, be a good one.", "Abraham Lincoln"),
        ("Success is not final, failure is not fatal: it is the courage to continue that counts.", "Winston Churchill"),
        ("The future belongs to those who believe in the beauty of their dreams.", "Eleanor Roosevelt"),
        ("Injustice anywhere is a threat to justice everywhere.", "Martin Luther King Jr."),
        ("Do not pray for easy lives. Pray to be stronger men.", "John F. Kennedy")
    ]

    // Key for UserDefaults
    let historyKey = "TipHistory"

    // Calculate tip
    var tipAmount: Double {
        let value = Double(amount) ?? 0
        return value * tipPercent / 100
    }

    // Calculate total
    var totalAmount: Double {
        let value = Double(amount) ?? 0
        return value + tipAmount
    }

    var body: some View {
        NavigationView {
            Form {
                // Amount input section
                Section(header: Text("Enter Amount")) {
                    TextField("$", text: $amount)
                        .keyboardType(.decimalPad)
                }

                // Tip percentage slider
                Section(header: Text("Tip Percentage")) {
                    VStack(alignment: .leading) {
                        Slider(value: $tipPercent, in: 5...30, step: 1)
                        Text("Tip: \(Int(tipPercent))%")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }

                // Calculation result + save button
                Section(header: Text("Calculation")) {
                    Text("Tip: $\(tipAmount, specifier: "%.2f")")
                    Text("Total: $\(totalAmount, specifier: "%.2f")")

                    Button("Save Record") {
                        saveRecord()
                    }
                }

                // Random quote (two-line layout)
                Section(header: Text("💬 Quote of the Day")) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\"\(randomQuoteText)\"")
                            .italic()
                            .foregroundColor(.gray)
                        Text("– \(randomQuoteAuthor)")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                }

                // Saved history
                if !history.isEmpty {
                    Section(header: Text("🧾 Recent History")) {
                        ForEach(history.reversed(), id: \.self) { entry in
                            Text(entry)
                        }
                    }
                }
            }
            .navigationTitle("TipView")
            .onAppear {
                let selected = quotes.randomElement()!
                randomQuoteText = selected.text
                randomQuoteAuthor = selected.author
                loadHistory()
            }
        }
    }

    // Save current calculation to history
    func saveRecord() {
        guard let bill = Double(amount), bill > 0 else { return }
        let entry = String(format: "$%.2f + %d%% = $%.2f", bill, Int(tipPercent), totalAmount)

        history.append(entry)
        UserDefaults.standard.set(history, forKey: historyKey)
    }

    // Load saved history from UserDefaults
    func loadHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: historyKey) {
            history = saved
        }
    }
}

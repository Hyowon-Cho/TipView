import SwiftUI

struct ContentView: View {
    // Store dark mode preference
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Input states
    @State private var amount: String = ""
    @State private var tipPercent: Double = 15
    @State private var numberOfPeople: Int = 2

    // Quote states
    @State private var randomQuoteText: String = ""
    @State private var randomQuoteAuthor: String = ""

    // History of calculations
    @State private var history: [String] = []

    // Alert states for input validation
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

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

    let historyKey = "TipHistory"

    // Calculate tip
    var tipAmount: Double {
        let bill = Double(amount) ?? -1
        guard bill > 0 else { return 0 }
        return bill * tipPercent / 100
    }

    // Calculate total
    var totalAmount: Double {
        let bill = Double(amount) ?? -1
        guard bill > 0 else { return 0 }
        return bill + tipAmount
    }

    // Calculate per person values
    var tipPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return tipAmount / Double(numberOfPeople)
    }

    var totalPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return totalAmount / Double(numberOfPeople)
    }

    var body: some View {
        NavigationView {
            Form {
                // Amount input
                Section(header: Text("Enter Amount")) {
                    TextField("Enter total bill", text: $amount)
                        .keyboardType(.decimalPad)
                }

                // Tip percentage slider
                Section(header: Text("Tip Percentage")) {
                    VStack(alignment: .leading) {
                        Slider(value: $tipPercent, in: 5...30, step: 1)
                        Text("Tip: \(Int(tipPercent))%")
                            .foregroundColor(.gray)
                    }
                }

                // Number of people
                Section(header: Text("Number of People")) {
                    Stepper(value: $numberOfPeople, in: 1...20) {
                        Text("\(numberOfPeople) \(numberOfPeople == 1 ? "person" : "people")")
                    }
                }

                // Tip + total + save
                Section(header: Text("Calculation")) {
                    Text("Tip: $\(tipAmount, specifier: "%.2f")")
                    Text("Total: $\(totalAmount, specifier: "%.2f")")

                    Button("Save Record") {
                        saveRecord()
                    }
                }

                // Split result
                Section(header: Text("Split Result")) {
                    Text("Tip per person: $\(tipPerPerson, specifier: "%.2f")")
                    Text("Total per person: $\(totalPerPerson, specifier: "%.2f")")
                }

                // Quote of the day
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

                // History + clear button
                if !history.isEmpty {
                    Section(header: Text("🧾 Recent History")) {
                        ForEach(history.reversed(), id: \.self) { entry in
                            Text(entry)
                        }

                        Button("Clear History") {
                            clearHistory()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("TipView")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    }
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Input"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                loadHistory()
                let quote = quotes.randomElement()!
                randomQuoteText = quote.text
                randomQuoteAuthor = quote.author
            }
        }
    }

    // Save calculation record with validation
    func saveRecord() {
        guard !amount.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Please enter a bill amount."
            showAlert = true
            return
        }
        guard let bill = Double(amount), bill > 0 else {
            alertMessage = "Enter a valid number greater than 0."
            showAlert = true
            return
        }
        let entry = String(format: "$%.2f + %d%% = $%.2f", bill, Int(tipPercent), totalAmount)
        history.append(entry)
        UserDefaults.standard.set(history, forKey: historyKey)
    }

    // Load saved history
    func loadHistory() {
        if let saved = UserDefaults.standard.stringArray(forKey: historyKey) {
            history = saved
        }
    }

    // Clear all saved history
    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}

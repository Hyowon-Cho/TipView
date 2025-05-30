import SwiftUI

struct ContentView: View {
    @State private var amount: String = ""
    @State private var tipPercent: Double = 15
    @State private var randomQuote: String = ""

    // Famous quotes to display randomly
    let quotes = [
        "It is better to be alone than in bad company. – George Washington",
        "The only true wisdom is in knowing you know nothing. – Socrates",
        "Life is like riding a bicycle. To keep your balance, you must keep moving. – Albert Einstein",
        "I have a dream. – Martin Luther King Jr.",
        "Whatever you are, be a good one. – Abraham Lincoln",
        "Success is not final, failure is not fatal: it is the courage to continue that counts. – Winston Churchill",
        "The future belongs to those who believe in the beauty of their dreams. – Eleanor Roosevelt",
        "Injustice anywhere is a threat to justice everywhere. – Martin Luther King Jr.",
        "Do not pray for easy lives. Pray to be stronger men. – John F. Kennedy"
    ]

    var tipAmount: Double {
        let value = Double(amount) ?? 0
        return value * tipPercent / 100
    }

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

                // Calculation result
                Section(header: Text("Calculation")) {
                    Text("Tip: $\(tipAmount, specifier: "%.2f")")
                    Text("Total: $\(totalAmount, specifier: "%.2f")")
                }

                // Random quote
                Section(header: Text("💬 Quote of the Day")) {
                    Text(randomQuote)
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .navigationTitle("Tip Calculator")
            .onAppear {
                randomQuote = quotes.randomElement() ?? ""
            }
        }
    }
}

import SwiftUI
import Charts

// Model for storing each tip record with category
struct TipRecord: Identifiable, Codable {
    let id: UUID
    let bill: Double
    let tip: Double
    let category: String
    let date: Date
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let total: Double
}

struct ContentView: View {
    // Store dark mode preference
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Input states
    @State private var amount: String = ""
    @State private var tipPercent: Double = 15
    @State private var numberOfPeople: Int = 2
    @State private var selectedCategory: String = "Delivery"

    // Quote states
    @State private var randomQuoteText: String = ""
    @State private var randomQuoteAuthor: String = ""

    // Records stored
    @State private var records: [TipRecord] = []

    // Categories list
    let categories = ["Delivery", "Fine Dining", "Sushi", "Meat", "Other"]

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

    let recordsKey = "TipRecords"

    // Alert states for input validation
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // Computed properties for calculations
    var tipAmount: Double {
        let bill = Double(amount) ?? -1
        guard bill > 0 else { return 0 }
        return bill * tipPercent / 100
    }

    var totalAmount: Double {
        let bill = Double(amount) ?? -1
        guard bill > 0 else { return 0 }
        return bill + tipAmount
    }

    var tipPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return tipAmount / Double(numberOfPeople)
    }

    var totalPerPerson: Double {
        guard numberOfPeople > 0 else { return 0 }
        return totalAmount / Double(numberOfPeople)
    }

    // Extract tip values for recent chart
    var tipValues: [Double] {
        records.map { $0.tip }
    }

    // Aggregate tip totals by category
    var categoryTotals: [String: Double] {
        var dict: [String: Double] = [:]
        for record in records {
            dict[record.category, default: 0] += record.tip
        }
        return dict
    }

    // Determine top category by total tip
    var topCategory: String {
        if let (cat, _) = categoryTotals.max(by: { $0.value < $1.value }) {
            return cat
        }
        return "None"
    }

    // Convert categoryTotals into array for chart
    var categoryDataArray: [CategoryData] {
        categoryTotals.map { CategoryData(category: $0.key, total: $0.value) }
    }

    var body: some View {
        NavigationView {
            Form {
                // Amount input
                Section(header: Text("Enter Amount")) {
                    TextField("Enter total bill", text: $amount)
                        .keyboardType(.decimalPad)
                }

                // Category picker
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
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

                // Recent tip amounts chart
                if !tipValues.isEmpty {
                    Section(header: Text("📊 Recent Tips")) {
                        Chart {
                            ForEach(Array(tipValues.enumerated()), id: \.offset) { index, value in
                                BarMark(
                                    x: .value("Entry", index + 1),
                                    y: .value("Tip Amount", value)
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                }

                // Category totals chart & top category
                if !categoryDataArray.isEmpty {
                    Section(header: Text("📈 Tips by Category")) {
                        Chart {
                            ForEach(categoryDataArray) { data in
                                BarMark(
                                    x: .value("Category", data.category),
                                    y: .value("Total Tips", data.total)
                                )
                            }
                        }
                        .frame(height: 200)
                        Text("Top Category: \(topCategory)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                // History + clear button
                if !records.isEmpty {
                    Section(header: Text("🧾 Recent History")) {
                        ForEach(records.reversed()) { record in
                            Text(String(format: "$%.2f + %d%% = $%.2f (%@)",
                                         record.bill,
                                         Int(tipPercent),
                                         record.bill + record.tip,
                                         record.category))
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
                loadRecords()
                let quote = quotes.randomElement()!
                randomQuoteText = quote.text
                randomQuoteAuthor = quote.author
            }
        }
    }

    // Save calculation record with category
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
        let tipValue = bill * tipPercent / 100
        let record = TipRecord(id: UUID(), bill: bill, tip: tipValue, category: selectedCategory, date: Date())
        records.append(record)
        saveRecordsToDefaults()
    }

    // Persistence using UserDefaults
    func saveRecordsToDefaults() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }

    func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([TipRecord].self, from: data) {
            records = decoded
        }
    }

    func clearHistory() {
        records.removeAll()
        UserDefaults.standard.removeObject(forKey: recordsKey)
    }
}

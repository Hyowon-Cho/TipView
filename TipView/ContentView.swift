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

// Data structure for charting category totals
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

    // Records stored
    @State private var records: [TipRecord] = []

    // Categories list
    let categories = [
        "Delivery",
        "Fine Dining",
        "Sushi",
        "Meat",
        "Cafe",
        "Fast Food",
        "Bakery",
        "Seafood",
        "Vegetarian",
        "Brunch",
        "Bar",
        "Buffet",
        "Food Truck",
        "Grocery",
        "Other"
    ]

    // Alert states for input validation
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let recordsKey = "TipRecords"

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

    // Aggregate tip totals by category
    var categoryTotals: [String: Double] {
        var dict: [String: Double] = [:]
        for record in records {
            dict[record.category, default: 0] += record.tip
        }
        return dict
    }

    // Convert categoryTotals into array for chart
    var categoryDataArray: [CategoryData] {
        categoryTotals.map { CategoryData(category: $0.key, total: $0.value) }
    }

    var body: some View {
        NavigationView {
            Form {
                // 1. Enter Amount
                Section(header: Text("Enter Amount")) {
                    TextField("Enter total bill", text: $amount)
                        .keyboardType(.decimalPad)
                }

                // 2. Tip Percentage
                Section(header: Text("Tip Percentage")) {
                    VStack(alignment: .leading) {
                        Slider(value: $tipPercent, in: 5...30, step: 1)
                        Text("Tip: \(Int(tipPercent))%")
                            .foregroundColor(.gray)
                    }
                }

                // 3. Number of People
                Section(header: Text("Number of People")) {
                    Stepper(value: $numberOfPeople, in: 1...20) {
                        Text("\(numberOfPeople) \(numberOfPeople == 1 ? "person" : "people")")
                    }
                }

                // 4. Category
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // 5. Calculation
                Section(header: Text("Calculation")) {
                    Text("Tip: $\(tipAmount, specifier: "%.2f")")
                    Text("Total: $\(totalAmount, specifier: "%.2f")")
                    Button("Save Record") {
                        saveRecord()
                    }
                }

                // 6. Split Result
                Section(header: Text("Split Result")) {
                    Text("Tip per person: $\(tipPerPerson, specifier: "%.2f")")
                    Text("Total per person: $\(totalPerPerson, specifier: "%.2f")")
                }

                // 7. Tips by Category
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
                    }
                }

                // 8. Recent History
                if !records.isEmpty {
                    Section(header: Text("🧾 Recent History")) {
                        ForEach(records.reversed()) { record in
                            Text(String(
                                format: "$%.2f + %d%% = $%.2f (%@)",
                                record.bill,
                                Int(tipPercent),
                                record.bill + record.tip,
                                record.category
                            ))
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

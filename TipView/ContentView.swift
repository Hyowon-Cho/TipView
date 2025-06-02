import SwiftUI
import Charts
import UserNotifications

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
    // MARK: – Dark Mode Preference
    @AppStorage("isDarkMode") private var isDarkMode = false

    // MARK: – Input States
    @State private var amount: String = ""
    @State private var tipPercent: Double = 15
    @State private var numberOfPeople: Int = 2
    @State private var selectedCategory: String = "Delivery"

    // MARK: – Stored Records
    @State private var records: [TipRecord] = []

    // MARK: – Categories List
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

    // MARK: – Alert States for Validation
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let recordsKey = "TipRecords"

    // MARK: – Computed Properties for Calculations
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

    // MARK: – Aggregate Tip Totals by Category
    var categoryTotals: [String: Double] {
        var dict: [String: Double] = [:]
        for record in records {
            dict[record.category, default: 0] += record.tip
        }
        return dict
    }

    // MARK: – Convert categoryTotals into Array for Chart
    var categoryDataArray: [CategoryData] {
        categoryTotals.map { CategoryData(category: $0.key, total: $0.value) }
    }

    // MARK: – Compute Total Tip Used in the Past Week
    var lastWeekTipSum: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else {
            return 0
        }
        return records
            .filter { $0.date >= oneWeekAgo && $0.date <= now }
            .reduce(0) { $0 + $1.tip }
    }

    // MARK: – Date Formatter for History Display
    static let recordDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

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
                                format: "%@ – $%.2f + $%.2f = $%.2f (%@)",
                                ContentView.recordDateFormatter.string(from: record.date),
                                record.bill,
                                record.tip,
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
                requestNotificationPermission()
                scheduleWeeklyTipReminder()
            }
        }
    }

    // MARK: – Save calculation record with category
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
        let record = TipRecord(
            id: UUID(),
            bill: bill,
            tip: tipValue,
            category: selectedCategory,
            date: Date()
        )
        records.append(record)
        saveRecordsToDefaults()
    }

    // MARK: – Persistence using UserDefaults
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

    // MARK: – Request Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            // Permission result handled silently
        }
    }

    // MARK: – Schedule Weekly Tip Reminder (Every Sunday at 10 AM)
    func scheduleWeeklyTipReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["weeklyTipReminder"])

        let content = UNMutableNotificationContent()
        content.title = "TipView Weekly Summary"
        content.body = String(format: "Last week you spent $%.2f on tips.", lastWeekTipSum)
        content.sound = .default

        // Create date components for Sunday (weekday = 1) at 10:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1      // Sunday in Calendar.current
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weeklyTipReminder",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}

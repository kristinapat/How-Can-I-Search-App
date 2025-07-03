import Foundation

class CSVLoader {
    func loadCSV(from fileName: String) -> [PoliceLink] {
        var links: [PoliceLink] = []

        guard let filepath = Bundle.main.path(forResource: fileName, ofType: "csv") else {
            print("CSV file not found")
            return []
        }

        do {
            let contents = try String(contentsOfFile: filepath)
            let rows = contents.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            for (index, row) in rows.enumerated() {
                if index == 0 { continue } // Skip header

                let columns = parseCSVRow(row)
                if columns.count >= 8 {
                    let link = PoliceLink(
                        state: columns[0],
                        city: columns[1],
                        county: columns[2],
                        sourceType: columns[3],
                        name: columns[5],
                        url: columns[4],
                        description: columns[6],
                        group_id:columns[7]
                    )
                    links.append(link)
                } else {
                    print("Invalid row at index \(index): \(columns)")
                }
            }
        } catch {
            print("Error reading CSV: \(error)")
        }

        return links
    }

    // Basic CSV parser that handles quoted commas
    private func parseCSVRow(_ row: String) -> [String] {
        var results: [String] = []
        var current = ""
        var insideQuotes = false

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                results.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }

        results.append(current.trimmingCharacters(in: .whitespacesAndNewlines)) // Add last field
        return results
    }
}

import SwiftUI
import SafariServices

// MARK: - Theme

struct ColorTheme {
    let base: Color
    let highlight: Color
}

// MARK: - Auto‐Scaling Text

struct AutoFittingText: View {
    let text: String
    let maxWidth: CGFloat
    var underline: Bool = false

    @State private var fontSize: CGFloat = 38

    var body: some View {
        Text(text)
            .font(.custom("Times New Roman", size: fontSize))
            .foregroundColor(.black)
            .underline(underline)
            .fontWeight(.bold)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .onAppear { adjustFont() }
    }

    private func adjustFont() {
        let testLabel = UILabel()
        testLabel.text = text
        testLabel.font = UIFont(name: "Times New Roman", size: fontSize)
        while testLabel.intrinsicContentSize.width > maxWidth && fontSize > 10 {
            fontSize -= 1
            testLabel.font = UIFont(name: "Times New Roman", size: fontSize)
        }
    }
}

// MARK: - In‐App Browser

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - City Section

struct CitySectionView: View {
    let city: String
    let links: [PoliceLink]
    let highlightColor: Color
    let startIndex: Int
    @Binding var selectedURL: URL?

    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            if city != "Colleges and Universities" && city != "District of Columbia" {

                GeometryReader { geo in
                    AutoFittingText(text: city, maxWidth: geo.size.width + 2)
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .background(highlightColor)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(height: 60)
            }

            ForEach(Array(links.enumerated()), id: \.1.id) { idx, link in
                let displayIndex = startIndex + idx + 1

                GeometryReader { geo in
                    Button(action: {
                        let cleaned = link.url
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        if let cleaned, let url = URL(string: cleaned),
                           let scheme = url.scheme?.lowercased(),
                           scheme == "http" || scheme == "https" {
                            selectedURL = url
                        } else {
                            print("❌ Invalid URL: \(link.url)")
                        }
                    }) {
                        AutoFittingText(
                            text: "\(displayIndex). \(link.sourceType)",
                            maxWidth: geo.size.width - 2,
                            underline: true
                        )
                        .padding(.horizontal, 5)
                    }
                }
                .frame(height: 22)
            }
        }
    }
}

// MARK: - State Section

struct StateSectionView: View {
    let state: String
    let links: [PoliceLink]
    let theme: ColorTheme
    @Binding var selectedURL: URL?

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Use larger state-level box only for Colleges and Universities
            if state == "Colleges and Universities" {
                Text("Colleges & Universities")
                    .font(.custom("Times New Roman", size: 38))
                    .fontWeight(.bold)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                   
                    .background(theme.highlight)
                    .foregroundColor(.black)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            else   if state == "District of Columbia" {
                Text(state)
                    .font(.custom("Times New Roman", size: 37))
                    .fontWeight(.bold)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .background(theme.highlight)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.black)
            } else {
                Text(state)
                    .font(.custom("Times New Roman", size: 47))
                    .fontWeight(.bold)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .background(theme.highlight)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.black)
            }

            let cityGroups = Dictionary(grouping: links, by: \.city)
            let sortedCities = cityGroups.keys.sorted {
                let special = "State of \(state)"
                if $0 == special { return false }
                if $1 == special { return true }
                return $0 < $1
            }

            let cityData: [(String, [PoliceLink], Int)] = sortedCities.reduce(into: []) { acc, city in
                guard let cityLinks = cityGroups[city] else { return }
                let offset = acc.reduce(0) { $0 + $1.1.count }
                acc.append((city, cityLinks, offset))
            }

            ForEach(cityData, id: \.0) { cityName, cityLinks, startIndex in
                CitySectionView(
                    city: cityName,
                    links: cityLinks,
                    highlightColor: theme.highlight,
                    startIndex: startIndex,
                    selectedURL: $selectedURL
                )
            }
        }
        .padding()
        .background(theme.base)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 6))
        .cornerRadius(10)
        .padding(.horizontal, 2)
    }
}

// MARK: - Main ContentView

struct ContentView: View {
    @State private var links: [PoliceLink] = []
    @State private var theme: ColorTheme = ColorTheme(base: .black, highlight: .white)
    @State private var selectedURL: URL?
    @State private var searchText: String = ""

    private var filteredLinks: [PoliceLink] {
        guard !searchText.isEmpty else { return links }
        let q = searchText.lowercased()
        return links.filter {
            $0.state.lowercased().contains(q) ||
            $0.city.lowercased().contains(q) ||
            $0.county.lowercased().contains(q) ||
            $0.sourceType.lowercased().contains(q) ||
            $0.name.lowercased().contains(q) ||
            $0.url.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            theme.base.ignoresSafeArea()

            ScrollView(.vertical,  showsIndicators: true) {
                VStack(alignment: .center, spacing: 8) {
               
                    Text("How Can I Search")
                        .font(.custom("Times New Roman", size: 60))
                        .kerning(-5.5)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
                    
                        .multilineTextAlignment(.center)
                        .padding(12) // ✅ Add padding inside the box
                    
                        .background(theme.highlight)
                        .padding(.top, 4) // Optional: spacing from top
                    
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    VStack(alignment: .center, spacing: 8) {
                                         
                                           Text("Search")
                                               .font(.custom("Times New Roman", size: 45))
                                               .fontWeight(.bold)
                                               .frame(maxWidth: .infinity)
                                               .foregroundColor(.black)
                                               .background(theme.highlight)
                                           
                                               .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 6))
                                               .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("", text: $searchText, prompt: Text("Enter city, county, or name…")
                            .font(.custom("Times New Roman", size: 24))
                            .foregroundColor(.black)
                                  
                        )
                        .font(.custom("Times New Roman", size: 24))
                        .fontWeight(.bold)
                        .textCase(.lowercase)
                        .multilineTextAlignment(.center) // ✅ center-align input text
                        .padding(10)
                        .background(theme.highlight)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 8)
                        .foregroundColor(.black)

                                     

                                       }
                    .padding()
                    .background(theme.base)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 7)

                    let grouped = Dictionary(grouping: filteredLinks, by: \.state)
                    let sortedStates = grouped.keys.sorted {
                        if $0 == "Colleges and Universities" { return true }
                        if $1 == "Colleges and Universities" { return false }
                        return $0 < $1
                    }

                    ForEach(sortedStates, id: \.self) { state in
                        if let stateLinks = grouped[state] {
                            StateSectionView(
                                state: state,
                                links: stateLinks,
                                theme: theme,
                                selectedURL: $selectedURL
                            )
                        }
                    }
                }
                .padding(.bottom, 20)

                VStack(alignment: .center, spacing: 10) {
                    Text("© 2025 Talk Dallas Crime")
                        .font(.custom("Times New Roman", size: 30))
                        .fontWeight(.bold)
                        .padding(9)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .background(theme.highlight)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 5.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .underline(true)
                        .padding(12) // ✅ Add padding inside the box
                        .padding(.top, 4) // Optional: spacing from top
                        .onTapGesture {
                            if let url = URL(string: "https://TalkDallasCrime.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.bottom, 10)
                }
            }
            .refreshable {
                withAnimation(.easeInOut(duration: 0.4)) {
                    refreshData()
                }
            }

            if let url = selectedURL {
                SafariView(url: url)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { selectedURL = nil }) {
                                                                   Image(systemName: "xmark.circle.fill")
                                                                       .font(.largeTitle)
                                                                       .foregroundColor(theme.base)
                                                                       .padding()
                                                                       .background(Color.black.opacity(0.6))
                                                                       .background(theme.highlight)
                                                                       .clipShape(Circle())
                                                               }
                            }
                            Spacer()
                        }
                    )
            }
        }
        .onAppear {
            theme = generateRandomTheme()
            links = CSVLoader().loadCSV(from: "policelinks")
        }
    }

    private func refreshData() {
        theme = generateRandomTheme()
        links = CSVLoader().loadCSV(from: "policelinks")
    }

    private func generateRandomTheme() -> ColorTheme {
        let base = Color(
            hue: Double.random(in: 0...1),
            saturation: Double.random(in: 0.5...1.0),
            brightness: Double.random(in: 0.7...1.0)
        )
        let highlight = base.lighter(by: 0.1)
        return ColorTheme(base: highlight, highlight: base)
    }
}

// MARK: - Color Helpers

extension Color {
    func lighter(by amount: Double = 0.1) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            red: min(Double(r) + amount, 1.0),
            green: min(Double(g) + amount, 1.0),
            blue: min(Double(b) + amount, 1.0)
        )
    }
}

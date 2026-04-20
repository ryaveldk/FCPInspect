import SwiftUI

/// In-app guide shown as a sheet. Split into two concrete workflows that
/// a post-assistant can follow without leaving the app.
struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .find

    enum Tab: String, CaseIterable, Identifiable {
        case find = "Find duplikater"
        case fix = "Ret op"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            Divider().background(Theme.stroke)
            ScrollView {
                switch selectedTab {
                case .find: findContent
                case .fix: fixContent
                }
            }
            .background(Theme.canvas)
        }
        .frame(minWidth: 620, idealWidth: 680, minHeight: 520, idealHeight: 640)
        .background(Theme.canvas)
        .preferredColorScheme(.dark)
    }

    // MARK: Chrome

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sådan bruger du FCPInspect")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Find ghost-multicams og ret dem med en XML round-trip")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.textTertiary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(20)
        .background(Theme.surface)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(selectedTab == tab ? Theme.cyan : Theme.textSecondary)
                        Rectangle()
                            .fill(selectedTab == tab ? Theme.cyan : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.surface)
    }

    // MARK: "Find" tab

    private var findContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            callout(
                icon: "lightbulb.fill",
                title: "Hvad er en ghost-multicam?",
                body: "Når du match-framer (Shift+F) på en multicam hvis cachede snapshot er ude af sync med den aktuelle master, laver Final Cut Pro en parallel kopi med samme angle-struktur men ny UID. Du ser det ikke i UI'en — kun biblioteket vokser og performance daler. Problemet lever kun i bibliotekets database, ikke i FCPXML, så en round-trip renser det."
            )

            stepSection(title: "1. Eksportér FCPXML fra Final Cut Pro", steps: [
                "Marker biblioteket (grundig scan) eller den mistænkte multicam (hurtig scan) i sidebaren.",
                "File → Export XML… Vælg FCPXML 1.10 eller nyere.",
                "Gem filen et sted du husker — fx på skrivebordet."
            ])

            stepSection(title: "2. Scan i FCPInspect", steps: [
                "Træk .fcpxml-filen (eller .fcpxmld-bundle) ind i app-vinduet, eller ⌘O for at vælge.",
                "Du kan trække flere filer eller en hel mappe ind — de analyseres samlet.",
                "Checken kører automatisk. Et gult tal ved siden af \"Multicam Duplication\" i sidebaren viser hvor mange fund."
            ])

            stepSection(title: "3. Læs rapporten", steps: [
                "Klik på fundet i midten for at se detaljer til højre.",
                "\"Authoritative master\" er den kopi med nyeste modDate — den du beholder.",
                "\"Ghost duplicates\" er de ældre kopier som skal væk.",
                "Ingen fund betyder enten at der intet problem er, eller at du kun har eksporteret én enkelt multicam (hvor checken ikke kan sammenligne)."
            ])

            tip(text: "Hvis du ikke får nogen fund men er sikker på der er dupletter, så prøv at eksportere hele biblioteket i stedet for en enkelt multicam.")
        }
        .padding(24)
    }

    // MARK: "Fix" tab

    private var fixContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            callout(
                icon: "exclamationmark.triangle.fill",
                title: "FCPInspect retter ikke automatisk",
                body: "App'en rører aldrig dit bibliotek — den læser kun XML. Reparationen udfører du selv i Final Cut Pro. Princippet er enkelt: den korrupte snapshot-data lever kun i bibliotekets interne database. En round-trip gennem FCPXML renser den.",
                tint: Theme.severityWarning
            )

            stepSection(title: "Sådan gør du", steps: [
                "Luk projektet i FCP. Biblioteket må ikke være åbent andre steder.",
                "Backup biblioteket. Dupliker .fcpbundle-mappen i Finder og mærk den _BACKUP_før-multicam-fix. Altid.",
                "Eksportér det ramte projekt: marker projektet → File → Export XML… → FCPXML 1.10+.",
                "Opret et nyt, tomt bibliotek: File → New → Library…",
                "Importér FCPXML'en i det nye bibliotek: File → Import → XML…",
                "FCP genopbygger projektet. Ghost-multicams er væk fordi snapshot-dataen kun lå i det gamle bibliotek.",
                "Verificér: eksportér det nye projekt som FCPXML og kør det gennem FCPInspect igen. Rapporten skal nu sige \"No findings\".",
                "Arbejd videre i det rensede bibliotek. Arkivér eller slet det gamle når du har kørt et par dage uden problemer."
            ])

            dontSection(items: [
                "Slet ikke manuelt i .fcpbundle-mappen. Det korrumperer biblioteket.",
                "Duplicer ikke events mellem biblioteker — det kopierer snapshot-dataen med.",
                "Stol ikke blindt på Consolidate/Relink — det retter ikke ghost-multicams, kun manglende medier."
            ])
        }
        .padding(24)
    }

    // MARK: Building blocks

    private func callout(
        icon: String,
        title: String,
        body: String,
        tint: Color = Theme.cyan
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(tint.opacity(0.30), lineWidth: 1)
                )
        )
    }

    private func stepSection(title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.canvas)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Theme.cyan))
                        Text(step)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func tip(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 11))
                .foregroundStyle(Theme.cyan)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
                .italic()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceElevated.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func dontSection(items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gør ikke dette")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.severityError)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.severityError)
                            .padding(.top, 3)
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textPrimary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

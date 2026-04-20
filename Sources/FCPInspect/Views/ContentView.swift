import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var isShowingHelp = false
    @State private var copyFeedbackVisible = false

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 320)
        } content: {
            FindingsListView(onRequestHelp: { isShowingHelp = true })
                .navigationSplitViewColumnWidth(min: 280, ideal: 340)
        } detail: {
            FindingDetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                toolbarSummary
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        state.copyReportToPasteboard()
                        flashCopyFeedback()
                    } label: {
                        Label("Kopier rapport", systemImage: "doc.on.clipboard")
                    }
                    .disabled(state.isEmpty)

                    Button {
                        state.presentSaveReportPanel()
                    } label: {
                        Label("Gem rapport…", systemImage: "square.and.arrow.down")
                    }
                    .disabled(state.isEmpty)
                } label: {
                    Label(copyFeedbackVisible ? "Kopieret ✓" : "Rapport",
                          systemImage: "square.and.arrow.up")
                }
                .help("Eksportér scanning-rapporten som markdown")
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingHelp = true
                } label: {
                    Label("Sådan gør du", systemImage: "questionmark.circle")
                }
                .help("Sådan finder og retter du ghost-multicams")
            }
        }
        .sheet(isPresented: $isShowingHelp) {
            HelpSheet()
        }
        .background(Theme.canvas)
        .preferredColorScheme(.dark)
        .acceptsFCPXMLDrops()
    }

    private func flashCopyFeedback() {
        copyFeedbackVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            copyFeedbackVisible = false
        }
    }

    private var toolbarSummary: some View {
        HStack(spacing: 10) {
            if !state.errorMessages.isEmpty {
                Label("\(state.errorMessages.count) load error(s)", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.severityError)
                    .help(state.errorMessages.joined(separator: "\n"))
            }
            let mcCount = state.sources.reduce(0) { acc, src in
                acc + src.document.medias.filter { $0.multicam != nil }.count
            }
            Text("\(state.sources.count) source\(state.sources.count == 1 ? "" : "s") · \(mcCount) multicam\(mcCount == 1 ? "" : "s") · \(state.findings.count) finding\(state.findings.count == 1 ? "" : "s")")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

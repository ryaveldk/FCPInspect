import SwiftUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @State private var isShowingHelp = false
    @State private var copyFeedbackVisible = false

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 320)
        } detail: {
            VStack(spacing: 0) {
                tabBar
                Divider().background(Theme.stroke)
                switch state.primaryTab {
                case .overview:
                    OverviewView()
                case .findings:
                    findingsPane
                }
            }
            .background(Theme.canvas)
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

    // MARK: Tab bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppState.PrimaryTab.allCases) { tab in
                Button {
                    state.primaryTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(state.primaryTab == tab ? Theme.cyan : Theme.textSecondary)
                        if tab == .findings, !state.findings.isEmpty {
                            Text("\(state.findings.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.canvas)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Theme.severityWarning))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(state.primaryTab == tab ? Theme.cyan : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.surface)
    }

    // MARK: Findings pane (composite — list + detail side by side)

    private var findingsPane: some View {
        HSplitView {
            FindingsListView(onRequestHelp: { isShowingHelp = true })
                .frame(minWidth: 280, idealWidth: 340)
            FindingDetailView()
                .frame(minWidth: 380)
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

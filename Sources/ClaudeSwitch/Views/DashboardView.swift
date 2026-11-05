import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject private var store: AccountStore
    @StateObject private var desktopRuntime = DesktopProfileRuntime()
    @State private var editing: ClaudeAccount?
    @State private var showingAdd = false
    @State private var showingDelete: ClaudeAccount?
    @State private var updateMessage = ""
    @State private var updateRelease: GitHubRelease?
    @State private var showingUpdateAlert = false

    var body: some View {
        NavigationSplitView {
            List {
                Section("ACCOUNTS") {
                    ForEach(store.accounts) { account in
                        Label(account.name, systemImage: account.icon).tag(account.id)
                    }
                }
            }
            .navigationTitle("ClaudeSwitch")
            .toolbar { Button { showingAdd = true } label: { Image(systemName: "plus") }.help("Add account") }
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your accounts").font(.largeTitle.bold())
                        Text("Create any labels you need: Work, Personal, Company, Client A, Lab, and more.").foregroundStyle(.secondary)
                    }
                    if store.accounts.isEmpty {
                        ContentUnavailableView("Add your first account", systemImage: "person.crop.circle.badge.plus", description: Text("Create a label such as Work, Personal, Company or Client A. Then choose Desktop or CLI.")).frame(maxWidth: .infinity, minHeight: 180)
                    } else {
                        ForEach(store.accounts) { account in accountCard(account) }
                    }

                    GroupBox("Desktop profiles and account detection") {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("Each account has its own Claude Desktop profile directory. Desktop profile isolation uses Electron's user-data-dir launch argument and is not an Anthropic-supported multi-account API.", systemImage: "macwindow.on.rectangle")
                            Label("Running means ClaudeSwitch detected a process launched with that profile. It does not confirm which Claude identity is signed in.", systemImage: "lock.shield")
                            Text(desktopRuntime.detectionMessage).font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Spacer()
                                Button("Refresh process status") { desktopRuntime.refresh() }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                    }

                    GroupBox("App integrations") {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Claude Desktop launches an experimental isolated profile for each ClaudeSwitch account. Sign in separately inside each profile.", systemImage: "macwindow")
                            Label("Claude Code CLI opens Terminal with a dedicated CLAUDE_CONFIG_DIR for each account.", systemImage: "terminal")
                            Divider()
                            Toggle("Show optional Browser action on account cards", isOn: $store.showBrowserOption)
                                .onChange(of: store.showBrowserOption) { _, _ in store.saveSettings() }
                            if store.showBrowserOption {
                                Picker("Browser", selection: $store.preferredBrowser) {
                                    ForEach(["Default browser", "Google Chrome", "Safari", "Microsoft Edge", "Brave", "Firefox"], id: \.self) { Text($0).tag($0) }
                                }.onChange(of: store.preferredBrowser) { _, _ in store.saveSettings() }
                                Label("Browser uses the selected browser's existing profile and current Claude login. It does not create a separate account session.", systemImage: "info.circle")
                            } else {
                                Text("Browser integration is hidden. Enable it here whenever you want it available from the menu bar.").font(.caption).foregroundStyle(.secondary)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                    }

                    GroupBox("Optional updates") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Enable manual update checks", isOn: $store.updatesEnabled).onChange(of: store.updatesEnabled) { _, _ in store.saveSettings() }
                            TextField("GitHub repository (owner/repository)", text: $store.githubRepository)
                                .textFieldStyle(.roundedBorder).disabled(!store.updatesEnabled)
                                .onSubmit { store.saveSettings() }
                            HStack {
                                Button("Save settings") { store.saveSettings(); updateMessage = "Settings saved." }
                                    .disabled(!store.updatesEnabled)
                                Button("Check for updates") { Task { await checkForUpdates() } }
                                    .disabled(!store.updatesEnabled || store.githubRepository.isEmpty)
                            }
                            Text(updateMessage.isEmpty ? "No background updater. ClaudeSwitch only checks when you explicitly ask it to." : updateMessage)
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                    }

                    GroupBox("Privacy and diagnostics") {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("No admin access intended for normal use.", systemImage: "checkmark.shield")
                            Label("No system default browser changes or forced browser-profile creation.", systemImage: "checkmark.shield")
                            Label("No passwords, cookies or Claude tokens are read, copied or exported.", systemImage: "checkmark.shield")
                            Label("ClaudeSwitch metadata, per-account CLI config folders and isolated Desktop profile folders are created in your user Library.", systemImage: "folder")
                            Button("Export privacy-safe diagnostics") { exportDiagnostics() }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 5)
                    }
                    Text(store.statusMessage).font(.footnote).foregroundStyle(.secondary)
                }.padding(28).frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .onAppear { desktopRuntime.configure(accounts: store.accounts, baseDirectory: store.baseDirectory) }
        .onChange(of: store.accounts) { _, accounts in desktopRuntime.configure(accounts: accounts, baseDirectory: store.baseDirectory) }
        .onReceive(NotificationCenter.default.publisher(for: .claudeSwitchRequestAddAccount)) { _ in showingAdd = true }
        .sheet(isPresented: $showingAdd) { AccountEditorView(title: "Add account", account: nil) { store.addAccount($0) } }
        .sheet(item: $editing) { account in AccountEditorView(title: "Edit account", account: account) { store.updateAccount($0) } }
        .confirmationDialog("Remove \(showingDelete?.name ?? "account")?", isPresented: Binding(get: { showingDelete != nil }, set: { if !$0 { showingDelete = nil } }), titleVisibility: .visible) {
            Button("Remove account", role: .destructive) { if let account = showingDelete { store.deleteAccount(account) }; showingDelete = nil }
        } message: { Text("This removes its ClaudeSwitch label and metadata. It does not sign you out or delete browser sessions or Claude Code data.") }
        .alert("ClaudeSwitch updates", isPresented: $showingUpdateAlert) {
            Button("Open release page") { if let url = updateRelease?.html_url { NSWorkspace.shared.open(url) } }
            Button("Later", role: .cancel) {}
        } message: { Text(updateMessage) }
    }

    private func accountCard(_ account: ClaudeAccount) -> some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: account.icon).font(.title2).foregroundStyle(Color(hex: account.color)).frame(width: 44, height: 44).background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(account.name).font(.headline)
                    Text(account.tag.isEmpty ? (account.email.isEmpty ? "No tag or email" : account.email) : account.tag + (account.email.isEmpty ? "" : " · " + account.email)).font(.caption).foregroundStyle(.secondary)
                    Text("Desktop: \(desktopRuntime.status(for: account))").font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    Text("CLI folder: \(account.workingDirectory)").font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                }
                Spacer()
                Button { Launcher.openDesktop(account: account, store: store, runtime: desktopRuntime) } label: { Label("Desktop", systemImage: "macwindow") }
                Button { Launcher.openCode(account: account, store: store) } label: { Label("CLI", systemImage: "terminal") }
                if store.showBrowserOption {
                    Button { Launcher.openWeb(account: account, store: store) } label: { Label("Browser", systemImage: "globe") }
                }
                Menu {
                    Button("Edit", systemImage: "pencil") { editing = account }
                    Button("Remove", systemImage: "trash", role: .destructive) { showingDelete = account }
                } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton)
            }.padding(5)
        }
    }

    @MainActor private func checkForUpdates() async {
        store.saveSettings()
        do {
            let release = try await UpdateChecker.latestRelease(repository: store.githubRepository)
            updateRelease = release
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0-beta.2"
            let latest = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            if latest.compare(current, options: .numeric) == .orderedDescending {
                updateMessage = "A newer release is available: \(release.name ?? release.tag_name). Open the release page?"
                showingUpdateAlert = true
            } else {
                updateMessage = "You're up to date. Latest release: \(release.name ?? release.tag_name)."
            }
        } catch { updateMessage = error.localizedDescription }
    }

    private func exportDiagnostics() {
        do {
            let source = try store.exportDiagnostics()
            let panel = NSSavePanel()
            panel.nameFieldStringValue = source.lastPathComponent
            panel.allowedContentTypes = [.json]
            panel.begin { response in
                guard response == .OK, let destination = panel.url else { return }
                do { try FileManager.default.copyItem(at: source, to: destination); store.updateStatus("Diagnostics exported without account names, emails or session data.") }
                catch { store.updateStatus("Could not export diagnostics: \(error.localizedDescription)") }
            }
        } catch { store.updateStatus("Could not prepare diagnostics: \(error.localizedDescription)") }
    }
}

private struct AccountEditorView: View {
    let title: String
    let onSave: (ClaudeAccount) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var email: String
    @State private var tag: String
    @State private var icon: String
    @State private var color: String
    @State private var workingDirectory: String
    private let existing: ClaudeAccount?

    init(title: String, account: ClaudeAccount?, onSave: @escaping (ClaudeAccount) -> Void) {
        self.title = title; self.existing = account; self.onSave = onSave
        _name = State(initialValue: account?.name ?? "")
        _email = State(initialValue: account?.email ?? "")
        _tag = State(initialValue: account?.tag ?? "")
        _icon = State(initialValue: account?.icon ?? "person.crop.circle.fill")
        _color = State(initialValue: account?.color ?? "#4F8CFF")
        _workingDirectory = State(initialValue: account?.workingDirectory ?? NSHomeDirectory())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title2.bold())
            TextField("Account label (e.g. Company, Client A)", text: $name)
            TextField("Tag / organisation (optional)", text: $tag)
            TextField("Email (optional)", text: $email)
            Picker("Icon", selection: $icon) {
                Text("Person").tag("person.crop.circle.fill"); Text("Briefcase").tag("briefcase.fill")
                Text("Building").tag("building.2.fill"); Text("Code").tag("chevron.left.forwardslash.chevron.right"); Text("Star").tag("star.fill")
            }
            Picker("Colour", selection: $color) {
                Text("Blue").tag("#4F8CFF"); Text("Purple").tag("#A78BFA"); Text("Green").tag("#34A853")
                Text("Orange").tag("#F59E0B"); Text("Red").tag("#EF4444"); Text("Grey").tag("#8B8B8B")
            }
            HStack {
                VStack(alignment: .leading, spacing: 3) { Text("Claude Code CLI working folder").font(.subheadline); Text(workingDirectory).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                Spacer()
                Button("Choose folder") { chooseWorkingDirectory() }
            }
            HStack { Spacer(); Button("Cancel") { dismiss() }; Button("Save") {
                let result = ClaudeAccount(id: existing?.id ?? UUID(), name: name, tag: tag, email: email, icon: icon, color: color, createdAt: existing?.createdAt ?? .now, workingDirectory: workingDirectory)
                onSave(result); dismiss()
            }.buttonStyle(.borderedProminent).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }.padding(24).frame(width: 460)
    }

    private func chooseWorkingDirectory() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: workingDirectory, isDirectory: true)
        if panel.runModal() == .OK, let url = panel.url { workingDirectory = url.path }
    }
}

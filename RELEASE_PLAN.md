# ClaudeSwitch macOS v1–v5 implementation and release plan

This repository consolidates the product milestones into one macOS beta codebase. A source implementation is not the same as a verified, signed public release; use the release gates below.

## Product decisions

- Primary actions per account: **Desktop** and **CLI**.
- Browser action is optional, hidden by default, and enabled from Settings.
- Accounts are user-defined labels, not fixed Work/Personal enums.
- Updates are opt-in and manual; no silent auto-update.
- Local-first; no ClaudeSwitch account, cloud backend, telemetry or background daemon.

## Milestones

### v1 — Native foundation

- Menu-bar application shell and dashboard.
- Account CRUD with custom label/tag/email/icon/colour and CLI working directory.
- Local persistence and backward-compatible account decoding.
- First-run welcome flow.

### v2 — Claude launch experiences

- Claude Desktop launcher using macOS Launch Services.
- Claude Code CLI launcher using per-account `CLAUDE_CONFIG_DIR` and Terminal.
- Optional browser action controlled from Settings.
- Clear disclosure that Desktop and browser modes use their existing shared login contexts.

### v3 — Developer workflow

- Per-account CLI working directory.
- Per-account CLI config directories.
- CLI availability and working-directory checks with actionable status messages.
- Future extension points: iTerm2, VS Code and Cursor launch profiles. These are not claimed as implemented in this beta.

### v4 — Product experience

- First-run onboarding.
- Account editor and settings.
- Privacy-safe diagnostics export.
- Opt-in manual GitHub release check.
- Static landing page and user-facing setup guide.

### v5 — Public release preparation

- macOS CI build.
- App bundle and DMG packaging script.
- Homebrew Cask template.
- Security policy, contribution guide, QA checklist and release checklist.
- Developer ID signing and notarization are release-owner tasks requiring Apple credentials.

## macOS validation gates

1. `swift build -c release` succeeds on macOS 14 and latest supported macOS.
2. First launch shows onboarding once; completion persists across relaunch.
3. Account add/edit/delete and legacy account migration work without data loss.
4. Menu-bar actions show Desktop and CLI only by default; Browser appears only when enabled in Settings.
5. Desktop action launches the installed app and accurately reports shared-login behaviour.
6. CLI action creates distinct config directories for two accounts, uses each account's working directory and starts the `claude` command.
7. Missing CLI, missing working directory, missing Desktop app and denied Terminal automation all produce useful messages.
8. Manual update check validates repository input and opens the release page only after user confirmation.
9. Diagnostics contain no account names, emails, credentials, browser data or CLI config contents.
10. Test on Apple Silicon and Intel if publishing a universal build.

## Signing and notarization

Required release-owner assets:

- Apple Developer Program membership.
- Developer ID Application certificate in the signing keychain.
- App-specific bundle identifier and hardened runtime configuration.
- App Store Connect API key or notarytool keychain profile.

Example environment:

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Legal Name (TEAMID)"
export NOTARY_PROFILE="claudeswitch-notary"
export VERSION="1.0.0"
export BUILD_NUMBER="1"
./Scripts/build-macos-app.sh
```

Create the notary profile beforehand with `xcrun notarytool store-credentials`. The build script signs the app and DMG, submits the DMG, waits for notarization and staples the ticket when `NOTARY_PROFILE` is set. Verify with `spctl --assess --type open --context context:primary-signature -v build/ClaudeSwitch.app` and `xcrun stapler validate build/ClaudeSwitch-<version>.dmg`.

## GitHub release

1. Use the configured owner/repository `varunkkanjarla/ClaudeSwitch`; see `PUBLISHING.md` for GitHub Pages and Homebrew tap setup.
2. Create a public repository and push the reviewed source.
3. Tag a version `vX.Y.Z` and publish release notes.
4. Attach the signed, notarized DMG and SHA-256 checksum.
5. Update the Homebrew Cask URL and SHA-256, then publish the tap.
6. Enable GitHub Pages using the included workflow; the configured URL is `https://varunkkanjarla.github.io/ClaudeSwitch/`.
7. Test a clean install on a second Mac user account and a managed/corporate Mac where policy permits.

## Not included in this source beta

- No Apple Developer certificate or notarization credentials.
- No published domain, GitHub repository or Homebrew tap.
- No auto-update installer; update checking is manual only.
- No independent Claude Desktop sessions (not exposed by the supported public app interface).
- No IDE-specific Claude Code integration beyond launching the CLI in Terminal.

# ClaudeSwitch for macOS

ClaudeSwitch is a local-first macOS menu-bar utility for keeping named Claude environments and launching Claude Desktop or Claude Code CLI with the right local context.

> **Beta software.** Build and test on macOS before relying on it. Claude Desktop currently opens its existing login; it does not support independent per-account Desktop sessions through ClaudeSwitch. The optional browser action also uses the selected browser's existing profile.

## What users get

- Menu-bar popover with configurable accounts (Work, Personal, Company, Client A, Lab, or any labels users choose).
- Per-account **Desktop** and **CLI** launch actions.
- Claude Code CLI launches with a dedicated `CLAUDE_CONFIG_DIR` for each ClaudeSwitch account and the account's selected working directory.
- Optional **Browser** action. It is hidden by default and can be enabled in Settings. It opens the user's existing browser profile and does not create independent browser sessions.
- First-run welcome screen, account management, optional manual update checks, and privacy-safe diagnostics export.
- Local JSON settings and account metadata in `~/Library/Application Support/ClaudeSwitch/`.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools / Swift 5.9+
- Claude Desktop installed for the Desktop action
- Claude Code CLI installed and available as `claude` in Terminal for the CLI action

## Build and run

```bash
swift build
swift run
```

The app is a menu-bar app. Click its menu-bar icon to open the account switcher; choose **Manage accounts** to open the full dashboard.

## User journey

1. Launch ClaudeSwitch and complete the welcome screen.
2. Add an account with a label, optional tag/email, icon, colour and CLI working folder.
3. Click **Desktop** to open the installed Claude Desktop application. It uses the app's current signed-in identity.
4. Click **CLI** to open Terminal with that account's dedicated `CLAUDE_CONFIG_DIR`. Authenticate with Claude Code on first use.
5. Optionally enable Browser in Settings to expose the browser action in account cards.

## Account/session behaviour

| Action | Behaviour | Independent login? |
|---|---|---|
| Desktop | Opens the installed Claude Desktop app | No; uses the app's existing login |
| CLI | Starts `claude` with an account-specific `CLAUDE_CONFIG_DIR` | Separate CLI configuration/auth context; authenticate each one |
| Browser (optional) | Opens `claude.ai` in the selected browser | No; uses that browser profile's current login |

ClaudeSwitch never reads, copies, exports or manages Claude passwords, cookies or tokens. Claude Code itself manages authentication inside each configuration directory.

## Data and privacy

- Account labels, tags, email labels, icons, colours and settings are stored locally in Application Support.
- CLI configuration directories are created under `~/Library/Application Support/ClaudeSwitch/ClaudeCode/<account-id>/`.
- Removing an account removes only ClaudeSwitch account metadata. It does not automatically delete CLI config data or sign the user out.
- Diagnostics export excludes account labels, email addresses, browser data, credentials and CLI configuration contents.
- No cloud account, analytics service or background daemon is required.

## Optional browser action

Open **Manage accounts → App integrations → Show optional Browser action**. Select Default browser or a supported installed browser. The Browser button is hidden by default. It opens the selected browser's existing profile; it is not an account-isolated browser session.

## Updates

Update checks are opt-in and manual. Enter the public GitHub repository as `owner/repository`, enable update checks and click **Check for updates**. ClaudeSwitch does not silently download or install updates.

## Packaging

For local testing:

```bash
./Scripts/build-macos-app.sh
```

For a signed/notarized release, configure the environment variables described in `RELEASE_PLAN.md`. Do not distribute an unsigned beta as a production build.

## Project structure

```text
Sources/ClaudeSwitch/Models       Account model and migration
Sources/ClaudeSwitch/Services     Persistence, launchers, update checker
Sources/ClaudeSwitch/Views        Menu bar, dashboard, onboarding
Distribution/macOS                Info.plist
Distribution/Homebrew             Cask template
Scripts                           Build and release verification scripts
Website                           Static product landing page
QA                                macOS beta test checklist
.github/workflows                 macOS CI
```

## Known limitations

- Claude Desktop's account session is shared with the installed Desktop app. The Desktop button does not log out or switch identities.
- Browser mode uses the browser's current profile. It cannot keep two Claude logins independent inside one profile.
- Claude Code CLI requires a working `claude` command in the user's Terminal PATH. Some shell environments may need PATH setup in the user's shell profile.
- Terminal automation may trigger a macOS permission prompt. Company MDM policy can block Apple Events, unsigned apps or app installation.
- The project must be compiled, exercised and signed on macOS. Linux source parsing is not a substitute for macOS validation.

## License

MIT. See [LICENSE](LICENSE).

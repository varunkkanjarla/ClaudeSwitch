# ClaudeSwitch macOS beta test checklist

## Install and onboarding
- [ ] Build on macOS 14+ with `swift build -c release`.
- [ ] Launch with `swift run` and confirm the menu-bar icon appears.
- [ ] Confirm first-run welcome appears once and does not reappear after completion.
- [ ] Open Manage accounts and confirm the dashboard opens.

## Accounts
- [ ] Add Company, Personal and Client A with different labels, icons and colours.
- [ ] Edit each account and restart the app; confirm metadata persists.
- [ ] Delete one account and confirm other accounts remain.
- [ ] Confirm old `accounts.json` files migrate without losing Work/Personal names.

## Menu-bar UX
- [ ] By default each account card shows Desktop and CLI actions only.
- [ ] Browser action is not visible by default.
- [ ] Enable Browser in Settings; confirm Browser appears in menu bar and dashboard cards.
- [ ] Disable Browser; confirm it disappears again after restart.

## Claude Desktop
- [ ] With Claude Desktop installed, click Desktop and confirm the native app launches/activates.
- [ ] Confirm status explains that the installed Desktop app's existing login is used.
- [ ] With Desktop not installed, confirm a clear error is shown.

## Claude Code CLI
- [ ] Install Claude Code and ensure `claude` works in Terminal.
- [ ] Set two different working directories for two accounts.
- [ ] Click CLI for each account; confirm Terminal opens in the expected folder.
- [ ] Confirm each process has a distinct `CLAUDE_CONFIG_DIR` under Application Support.
- [ ] Authenticate each CLI config separately and verify the sessions remain distinct.
- [ ] Test a missing CLI and missing working folder; confirm actionable status messages.
- [ ] If macOS asks for Terminal automation permission, approve and repeat. Also test denied permission.

## Optional browser
- [ ] Enable Browser and open Claude in the default browser.
- [ ] Choose each supported browser that is installed and confirm it opens.
- [ ] Confirm ClaudeSwitch does not create profiles, read cookies or change system defaults.

## Updates and diagnostics
- [ ] Leave update checks disabled and confirm no network request is initiated by the UI.
- [ ] Enable update checks, enter `owner/repository`, and manually check a repository with a release.
- [ ] Try invalid repository values and a repository with no releases.
- [ ] Export diagnostics and inspect the JSON; ensure account labels, emails, tokens and session contents are absent.

## Release validation
- [ ] Sign app with Developer ID and Hardened Runtime.
- [ ] Notarize and staple the DMG.
- [ ] Verify Gatekeeper assessment and stapling.
- [ ] Test installation on a clean Mac account.
- [ ] Test both Apple Silicon and Intel if claiming universal support.

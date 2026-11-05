# Desktop profile isolation and account detection

## Design

Each ClaudeSwitch account maps to one persistent profile directory:

`~/Library/Application Support/ClaudeSwitch/DesktopProfiles/<account-uuid>/`

The directory is created with POSIX mode 0700. Claude Desktop is launched with Electron's `--user-data-dir=<path>` argument through `NSWorkspace.OpenConfiguration` with `createsNewApplicationInstance = true`.

ClaudeSwitch does not copy or inspect Claude Desktop profile contents. It does not access cookies, OAuth tokens, passwords, browser databases, Keychain entries, prompts or conversations.

## Detection model

The detector runs `/bin/ps -axo pid=,command=` locally and keeps only PIDs for main Claude Desktop processes whose command line contains the exact managed `--user-data-dir` argument. Electron child processes carrying `--type=` are excluded. Full command lines are not persisted or included in diagnostics.

The UI distinguishes process state from identity state:

- **Running**: a main process was found with this profile's launch argument.
- **Not running**: no matching process was found.
- **Identity not verified**: ClaudeSwitch does not inspect Claude Desktop's private authentication/session state.

An account email entered in ClaudeSwitch is descriptive metadata only, not proof of the signed-in identity.

## Safe operational behavior

- Repeated launch requests for a detected profile activate the existing process rather than opening a second process against the same profile directory.
- Removing an account from ClaudeSwitch preserves its profile directory and session data.
- The profile directory is never deleted automatically.
- Process detection is local and read-only.

## Compatibility caveat

This implementation depends on Electron's `--user-data-dir` argument and Claude Desktop accepting multiple instances. This is not a documented Anthropic multi-account API. Claude Desktop updates may change or reject this behavior.

If the app ignores the argument or multiple instances share a profile, stop using the feature for that Claude Desktop version. Do not copy profile databases or Keychain credentials as a workaround.

## Required manual validation on macOS

1. Create two ClaudeSwitch accounts.
2. Launch Desktop for account A and sign in to identity A.
3. Launch Desktop for account B and sign in to identity B.
4. Confirm both windows are visible at once and verify the identity in each window's own account menu.
5. Quit and relaunch each profile; confirm both sessions persist independently.
6. Restart ClaudeSwitch while both Desktop processes remain open; confirm the process status is rediscovered.
7. Upgrade Claude Desktop and repeat steps 2–6.
8. Confirm repeated clicks activate an existing matching process rather than starting a duplicate.
9. Confirm removing an account preserves its profile directory.

## Sign-in hand-off (Sign in this profile…)

1. With your main Claude Desktop and one other isolated profile open, choose **⋯ → Sign in this profile…** for account A.
2. Confirm the dialog lists both open windows by name and warns about Code tab sessions.
3. Choose **Quit and continue**; confirm both windows quit normally and only account A's Desktop opens.
4. Sign in with Google in the browser and choose **Open Claude**; confirm account A's window, not a new default window, receives the sign-in.
5. Click **Done**; confirm the main Claude Desktop reopens with its original identity.
6. Leave a window showing an unsaved-changes or quit prompt and repeat; confirm ClaudeSwitch stops with a message naming it and does not force-quit.
7. With only isolated profiles open, click **Desktop** on an account using the existing setup; confirm the main profile opens instead of an isolated window being activated.

A successful Swift build alone does not prove Claude Desktop's runtime isolation works. This smoke test is required before advertising the feature as supported.

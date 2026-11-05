# Contributing

Thanks for considering a contribution to ClaudeSwitch.

## Development

- macOS 14+
- Xcode 15+ / Swift 5.9+

```bash
swift build
swift run
```

## Guidelines

- Keep account metadata local by default.
- Never add code that reads, exports, copies, or manipulates browser cookies or Claude authentication tokens.
- Do not silently change the system default browser or create browser profiles without explicit opt-in.
- Explain any new macOS permissions and why they are needed.
- Add tests for account persistence, migration, and launch argument construction where possible.
- Keep macOS-specific code isolated so a future Windows implementation can use a separate platform layer.

## Pull requests

Describe the user problem, behavioural change, permissions involved, and manual test steps. Do not include personal account details, logs containing tokens, or employer-confidential information.

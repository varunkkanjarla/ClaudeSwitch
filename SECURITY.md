# Security Policy

## Data handled

ClaudeSwitch stores account labels, optional email addresses, icon/colour preferences, and app settings locally under the current macOS user's Application Support directory. ClaudeSwitch does not intentionally collect Claude passwords, browser cookies, OAuth tokens, API keys, prompts, or conversation content.

Claude Code manages its own credentials and data in the per-account `CLAUDE_CONFIG_DIR` passed to it by ClaudeSwitch. Those files are outside ClaudeSwitch's credential-management scope.

## Reporting a vulnerability

Please do not publish secrets, tokens, or personal data in an issue. Until a private security contact is configured for the repository, report suspected vulnerabilities through GitHub's private vulnerability reporting feature if enabled by the repository owner.

## Managed devices

Users should comply with employer software-installation, endpoint-management, and AI-use policies. ClaudeSwitch is designed not to require administrator privileges or modify system-wide browser settings, but organisations may restrict unsigned applications or Apple Events automation.

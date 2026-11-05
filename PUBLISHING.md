# ClaudeSwitch publishing setup

## Canonical project details

- GitHub owner: `varunkkanjarla`
- Main repository: `https://github.com/varunkkanjarla/ClaudeSwitch`
- Website (GitHub Pages): `https://varunkkanjarla.github.io/ClaudeSwitch/`
- Homebrew tap repository: `https://github.com/varunkkanjarla/homebrew-tap`
- Install command after the first signed release and tap publication:

  ```bash
  brew tap varunkkanjarla/tap
  brew install --cask claudeswitch
  ```

## 1. Create and push the main repository

Create a **public** GitHub repository named `ClaudeSwitch` under `varunkkanjarla` (do not initialize it with a README or license because those are included here). From this `ClaudeSwitch` directory:

```bash
 git init
 git add .
 git commit -m "Initial ClaudeSwitch macOS beta"
 git branch -M main
 git remote add origin https://github.com/varunkkanjarla/ClaudeSwitch.git
 git push -u origin main
```

## 2. Enable GitHub Pages

The included `.github/workflows/pages.yml` deploys the `Website/` folder whenever it changes on `main`.

In GitHub, open **Settings → Pages → Build and deployment** and select **GitHub Actions** as the source. The first deployment can take a few minutes. The website URL is:

`https://varunkkanjarla.github.io/ClaudeSwitch/`

## 3. Prepare a real macOS release

Do not publish a Cask pointing to a placeholder or unsigned beta. On a Mac with the required Apple Developer ID certificate and notarization credentials, follow `RELEASE_PLAN.md` and run:

```bash
VERSION=1.0.0 BUILD_NUMBER=1 \
DEVELOPER_ID_APPLICATION="Developer ID Application: YOUR LEGAL NAME (TEAMID)" \
NOTARY_PROFILE="claudeswitch-notary" \
./Scripts/build-macos-app.sh
```

This must produce `build/ClaudeSwitch-1.0.0.dmg` and `build/ClaudeSwitch-1.0.0.dmg.sha256`. Verify the app and DMG, test on a clean Mac account, and confirm notarization before public distribution. Apple signing identity and notary credentials are not included in this kit.

## 4. Create the Homebrew tap repository

Create a **public** GitHub repository named `homebrew-tap` under `varunkkanjarla`. Use the separate `homebrew-tap/` directory in this kit as its contents. The Cask is deliberately a template until a real signed release exists.

After creating a real release, edit `homebrew-tap/Casks/claudeswitch.rb`:

- Set `version` to the release version (without the `v` prefix).
- Replace the SHA placeholder with the exact SHA-256 from the DMG checksum file.
- Confirm the release URL returns the exact DMG.

Then push the tap repository:

```bash
cd ../homebrew-tap
git init
git add .
git commit -m "Add ClaudeSwitch cask"
git branch -M main
git remote add origin https://github.com/varunkkanjarla/homebrew-tap.git
git push -u origin main
```

Users can then install:

```bash
brew tap varunkkanjarla/tap
brew install --cask claudeswitch
```

## 5. Validate the Cask

On a Mac with Homebrew:

```bash
brew audit --new --cask claudeswitch
brew install --cask --verbose claudeswitch
brew info claudeswitch
brew uninstall --cask claudeswitch
```

Test installation and uninstall on a separate macOS user account before announcing availability.

## 6. Updating releases

For each new version:

1. Build, sign, notarize and test the DMG.
2. Create a GitHub Release in `varunkkanjarla/ClaudeSwitch` and attach the DMG plus checksum.
3. Update the version, download URL (if naming changes) and SHA-256 in the tap Cask.
4. Commit and push the tap update.
5. Update release notes and website download instructions.

The project currently uses opt-in manual update checks. It does not silently install updates.

## Current publication status

This kit configures repository names, website URLs, Pages deployment and the Homebrew tap structure. It does **not** create GitHub repositories, publish commits, own a domain, sign/notarize the app, upload a release asset, or publish a working installable Cask. Those steps require access to the GitHub account and Apple Developer credentials.

# Remove disabled packages GitHub Action

An action that deletes packages that have a disable date of more than one year ago.

## Usage

```yaml
- name: Remove disabled packages
  uses: Homebrew/actions/remove-disabled-packages@1f8e202ffddf94def7f42f6fa3a482e821489f9c # 2026.07.10.1
```

## Privacy

This Action contacts Chainguard's licensing server to verify authorization. Connection metadata (IP address, GitHub repository identifier, timestamp, and any metadata encoded in the auth token) is transmitted to Chainguard, Inc. even if authorization is denied in accordance with our [Privacy Notice](https://www.chainguard.dev/legal/privacy-notice)

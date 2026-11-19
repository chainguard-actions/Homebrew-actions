# Dismiss approvals GitHub Action

An action that dismisses all approved reviews on given pull request.

## Usage

```yaml
- name: Dismiss approvals
  uses: Homebrew/actions/dismiss-approvals@1f8e202ffddf94def7f42f6fa3a482e821489f9c # 2026.07.10.1
  with:
    token: ${{secrets.HOMEBREW_GITHUB_API_TOKEN}}
    pr: ${{github.event.pull_request.number}}
    message: workflow run failed
```

## Privacy

This Action contacts Chainguard's licensing server to verify authorization. Connection metadata (IP address, GitHub repository identifier, timestamp, and any metadata encoded in the auth token) is transmitted to Chainguard, Inc. even if authorization is denied in accordance with our [Privacy Notice](https://www.chainguard.dev/legal/privacy-notice)

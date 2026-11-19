# Post comment GitHub Action

An action that simply posts a new comment on given issue with specified content.

## Usage

> `bot_body` input will be used as comment body if `GITHUB_ACTOR` environment variable equals `bot` input. Otherwise `body` input is used.

```yaml
- name: Post comment
  uses: Homebrew/actions/post-comment@1f8e202ffddf94def7f42f6fa3a482e821489f9c # 2026.07.10.1
  with:
    token: ${{secrets.HOMEBREW_GITHUB_API_TOKEN}}
    issue: 123
    body: ${{github.actor}} has triggered this workflow.
    bot_body: BrewTestBot has triggered this workflow.
    bot: BrewTestBot
```

## Privacy

This Action contacts Chainguard's licensing server to verify authorization. Connection metadata (IP address, GitHub repository identifier, timestamp, and any metadata encoded in the auth token) is transmitted to Chainguard, Inc. even if authorization is denied in accordance with our [Privacy Notice](https://www.chainguard.dev/legal/privacy-notice)

# Create pull request GitHub Action

A very simple action to create a pull request from an already pushed branch.

Intended for internal use only.

## Usage

```yaml
- run: git commit ... && git push ...

- uses: Homebrew/actions/create-pull-request@1f8e202ffddf94def7f42f6fa3a482e821489f9c # 2026.07.10.1
  with:
    token: ${{ github.token }} # defaults to this
    repository: ${{ github.repository }} # defaults to this
    head: some-branch
    base: main
    title: Some optional title
    body: Some optional body
```

## Privacy

This Action contacts Chainguard's licensing server to verify authorization. Connection metadata (IP address, GitHub repository identifier, timestamp, and any metadata encoded in the auth token) is transmitted to Chainguard, Inc. even if authorization is denied in accordance with our [Privacy Notice](https://www.chainguard.dev/legal/privacy-notice)

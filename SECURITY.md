# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest  | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do not** open a public GitHub issue
2. Email **mailpriyanshugarg@gmail.com** with details
3. Include steps to reproduce if possible

You should receive a response within 48 hours. We'll work with you to understand and fix the issue before any public disclosure.

## Scope

Dime Money is a fully local app with no network calls. Security concerns primarily relate to:

- Local data storage (SQLite database)
- Biometric authentication bypass
- CSV import/export data handling

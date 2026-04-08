# lex-identity-aws

**Parent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

AWS IAM identity provider for LegionIO. Phase 6 cloud/machine provider. Resolves machine identity from STS `GetCallerIdentity` and provides session credentials via instance profile or AssumeRole.

**GitHub**: https://github.com/LegionIO/lex-identity-aws
**Gem**: `lex-identity-aws`
**Version**: 0.1.0
**License**: MIT
**Category**: `identity` (prefix match, phase 0, tier 0)

## Key Design Rules

- NEVER store `secret_access_key` or `session_token` in Lease metadata — only `access_key_id` + region + expiration
- Use STS client for default chain credentials (NOT `Aws::CredentialProviderChain` — internal API)
- Force-resolve lazy credentials with `.credentials` call
- Rescue `StandardError` (not just `Aws::Errors::ServiceError`) — `Aws::EC2Metadata::RequestError` is RuntimeError
- `canonical_name` derived from ARN role name segment (second slash-split segment)
- `provide_token` credential field is `access_key_id` only (non-secret identifier)
- Store actual `Aws::Credentials` object in `@credential_cache` — exposed via `current_credentials` for Phase 8 consumers
- `private_class_method` with explicit method names

## File Map

| Path | Purpose |
|------|---------|
| `lib/legion/extensions/identity/aws.rb` | Entry point — top-level module with `identity_provider?`, `remote_invocable?`, delegation methods |
| `lib/legion/extensions/identity/aws/identity.rb` | Provider contract: `resolve`, `provide_token`, `current_credentials`, `normalize` + private helpers |
| `lib/legion/extensions/identity/aws/settings.rb` | Settings module with ENV fallbacks |
| `lib/legion/extensions/identity/aws/version.rb` | VERSION constant |
| `spec/legion/extensions/identity/aws/identity_spec.rb` | Unit tests for Identity module |
| `spec/legion/extensions/identity/aws/settings_spec.rb` | Unit tests for Settings module |

## Dependencies

- `aws-sdk-core` >= 3.0
- `aws-sdk-sts` >= 1.0
- `legion-json` >= 1.2.1
- `legion-settings` >= 1.3.14

---

**Maintained By**: Matthew Iverson (@Esity)

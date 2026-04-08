# lex-identity-aws

AWS IAM identity provider for [LegionIO](https://github.com/LegionIO/LegionIO).

Resolves machine identity from AWS STS and provides session credentials via instance profile or AssumeRole. Part of the Phase 6 cloud/machine provider suite.

## Provider Contract

| Attribute | Value |
|-----------|-------|
| `provider_name` | `:aws` |
| `provider_type` | `:auth` |
| `facing` | `:machine` |
| `priority` | `90` |
| `trust_weight` | `100` |
| `capabilities` | `[:authenticate, :credentials]` |

## Usage

The provider auto-discovers via the `lex-identity-*` prefix in LegionIO's category registry and loads at phase 0 (before all other extensions).

At boot, `resolve` calls `sts.get_caller_identity` and derives a canonical name from the IAM role name segment of the ARN:

```
arn:aws:sts::123456789012:assumed-role/legion-worker/session  ->  legion-worker
arn:aws:iam::123456789012:role/my-role                        ->  my-role
```

`provide_token` returns a `Legion::Identity::Lease` with `credential` set to `access_key_id` only. The full `Aws::Credentials` object (including secret and session token) is cached in memory and accessible via `Identity.current_credentials` or `Broker.credentials_for(:aws)` (Phase 8).

## Security

`secret_access_key` and `session_token` are **never** stored in Lease metadata. Lease metadata is exposed via audit logs, `/api/stats`, and Apollo. Use `Broker.credentials_for(:aws)` for full credential access.

## Credential Chain

When `role_arn` is not configured, the provider uses an STS client to trigger the full AWS SDK default credential chain:

1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. Shared credentials file (`~/.aws/credentials`)
3. Web identity token (EKS IRSA)
4. ECS task role
5. EC2 instance profile (IMDSv2)

When `role_arn` is configured, `AssumeRoleCredentials` is used instead.

## Settings

Configure via `settings.json` under `identity.aws`:

```json
{
  "identity": {
    "aws": {
      "region": "us-east-2",
      "role_arn": "arn:aws:iam::123456789012:role/my-role",
      "session_duration": 3600,
      "profile": "vault-contributor"
    }
  }
}
```

All settings fall back to ENV vars: `AWS_REGION`, `AWS_DEFAULT_REGION`, `AWS_ROLE_ARN`, `AWS_PROFILE`.

## Dependencies

- `aws-sdk-core` >= 3.0
- `aws-sdk-sts` >= 1.0
- `legion-json` >= 1.2.1
- `legion-settings` >= 1.3.14

## License

MIT

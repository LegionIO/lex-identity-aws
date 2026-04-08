# Changelog

## [0.1.0] - 2026-04-07

### Added

- Initial release
- `Identity` module implementing the LegionIO identity provider contract
- `provider_type: :auth`, `facing: :machine`, `priority: 90`, `trust_weight: 100`
- `capabilities: [:authenticate, :credentials]`
- `resolve` calls STS `GetCallerIdentity` and derives `canonical_name` from the ARN role name segment
- `provide_token` resolves credentials via AssumeRole (when `role_arn` configured) or default chain,
  returns a `Legion::Identity::Lease` with only `access_key_id` + region in metadata (never `secret_access_key` or `session_token`)
- `current_credentials` exposes the cached `Aws::Credentials` object for Phase 8 consumers via `Broker.credentials_for`
- `default_chain_credentials` uses an STS client to trigger the full SDK credential chain (env vars, shared creds, web identity, ECS, instance profile)
- `StandardError` rescue in `default_chain_credentials` to handle `Aws::EC2Metadata::RequestError` (RuntimeError) and `Aws::Errors::NoSuchProfileError`
- Top-level delegation methods (`provider_name`, `provider_type`, `facing`) satisfy extension registration without enabling double-resolution
- `Settings` module with ENV fallbacks: `AWS_REGION`, `AWS_DEFAULT_REGION`, `AWS_ROLE_ARN`, `AWS_PROFILE`

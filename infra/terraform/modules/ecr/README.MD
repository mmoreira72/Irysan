# ECR Module

Creates and manages an AWS ECR repository with:
- Scan on push
- Optional immutable tags
- Encryption (AES256 or KMS)
- Lifecycle policy (default keeps 10 latest tagged and expires untagged after 7 days)
- Optional repository policy (attach JSON)

## Inputs
- `name` (string, required)
- `scan_on_push` (bool, default: true)
- `image_tag_mutability` (MUTABLE|IMMUTABLE, default: MUTABLE)
- `encryption_type` (AES256|KMS, default: AES256)
- `kms_key_arn` (string, when using KMS)
- `lifecycle_policy_json` (string JSON, optional)
- `force_delete` (bool, default: false)
- `repository_policy_json` (string JSON, optional)
- `tags` (map(string), optional)

## Outputs
- `repository_arn`, `repository_name`, `repository_url`

## Example
```hcl
module "ecr_app" {
  source = "./modules/ecr"
  name   = "hello-app"
  tags   = { Project = "eks-hello", Owner = "devops" }
}

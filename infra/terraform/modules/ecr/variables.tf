variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "scan_on_push" {
  description = "Enable image scan on push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "encryption_type" {
  description = "AES256 or KMS"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "kms_key_arn" {
  description = "KMS CMK ARN when encryption_type=KMS"
  type        = string
  default     = null
}

variable "lifecycle_policy_json" {
  description = "Lifecycle policy as JSON. If null, a sane default is applied."
  type        = string
  default     = null
}

variable "force_delete" {
  description = "If true, allow Terraform to delete the repo even if images exist"
  type        = bool
  default     = false
}

variable "repository_policy_json" {
  description = "Optional repository policy JSON (who can pull/push). If null, no policy is attached."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

// Defaults work out of the box against "snapcd-deployment-docker".

//// Provider init

variable "client_id" {
  default = "default"
}

variable "client_secret" {
  default   = "default"
  sensitive = true
}

variable "organization_id" {
  default = "10000000-0000-0000-0000-000000000000"
}

variable "snapcd_server_url" {
  // default = "http://localhost:5000"
  // How you reach the Server from where you run `terraform apply`.
  // - snapcd-deployment-docker:      "http://localhost:5000"
  - SnapCd.Server.Host (C# proj):  "https://localhost:20002"
  // - SaaS:                          "https://snapcd.io"
}

variable "insecure_skip_verify" {
  default = true
  // false if the Server has a valid certificate (e.g. https://snapcd.io)
}

//// The stack

variable "stack_name" {
  default = "prod"
}

//// Where the mock modules live
//
// Every snapcd_module below points at this repo and selects one directory under
// modules/<namespace>/<module>. Point it at your own fork if you want to edit
// the mocks and watch Snap CD pick up the change.

variable "source_url" {
  default = "https://github.com/schrieksoft/sample-modules.git"
}

variable "source_revision" {
  default = "main"
}

//// Runners
//
// One per credential boundary. In a real deployment these hold genuinely
// different credentials — that is the whole point (see full-mocked.md
// § Runners). For a local demo it is fine to point all four at the same
// Runner name: set every one of these to "default".

variable "azure_runner_name" {
  default = "default"
}

variable "k8s_runner_name" {
  default = "default"
}

variable "analytics_runner_name" {
  default = "default"
}

variable "identity_runner_name" {
  default = "default"
}

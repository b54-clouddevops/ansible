variable "service_accounts" {
  type = map(list(string))
  default = {
    "account1" = ["roles/storage.objectViewer", "roles/compute.viewer"],
    "account2" = ["roles/logging.viewer", "roles/iam.securityReviewer"],
    "account3" = ["roles/bigquery.dataViewer"],
  }
}

locals {
  project_id = "your-project-id"
}

provider "google" {
  credentials = file("path/to/your/credentials.json")
  project     = local.project_id
  region      = "us-central1"
}

resource "google_project_iam_member" "service_account_bindings" {
  for_each = var.service_accounts

  project = local.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.project_id}@${local.project_id}.iam.gserviceaccount.com"
}

resource "google_project_iam_binding" "custom_role_bindings" {
  for_each = var.service_accounts

  project = local.project_id
  role    = "roles/${each.key}"
  members = [
    "serviceAccount:${local.project_id}@${local.project_id}.iam.gserviceaccount.com",
  ]

  depends_on = [google_project_iam_member.service_account_bindings]
}

resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  account_id   = each.key
  display_name = each.key

  project = local.project_id
}

output "service_account_emails" {
  value = {
    for sa, roles in var.service_accounts : sa => google_service_account.service_accounts[sa].email
  }
}

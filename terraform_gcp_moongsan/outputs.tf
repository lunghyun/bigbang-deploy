
output "prod_vm_ip" {
  value = google_compute_address.prod_static_ip.address
}

# output "dev_vm_ip" {
#   value = google_compute_address.dev_static_ip.address
# }

# output "artifact_bucket_url" {
#   value = "gs://${google_storage_bucket.app_bucket.name}/artifacts/"
# }

# output "log_bucket_url" {
#   value = "gs://${google_storage_bucket.app_bucket.name}/logs/"
# }
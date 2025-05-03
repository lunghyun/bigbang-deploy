
variable "project_id" {
  description = "GCP Project ID"
  default = "ktb-2-moongsan"
  type        = string
}

variable "vm_machine_type" {
  default = "e2-medium"
}

variable "ubuntu_image" {
  default = "ubuntu-os-cloud/ubuntu-2204-lts"
  # Amazon Linux 2023
}

variable "ssh_user" {
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/lsh-study-key.pub"
}

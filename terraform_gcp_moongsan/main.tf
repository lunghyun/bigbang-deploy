# # GCS 버킷 생성
# resource "google_storage_bucket" "app_bucket" {
#   name          = "moongsan-bucket"
#   location      = "ASIA"
#   force_destroy = true  # 개발 중에는 이게 편함
#   uniform_bucket_level_access = true

#   lifecycle_rule {
#     action {
#       type = "Delete"
#     }
#     condition {
#       age = 90  # 90일 지난 파일 자동 삭제
#     }
#   }
# }

# 고정 IP 생성
resource "google_compute_address" "prod_static_ip" {
  name = "moongsan-prod-ip"
}

# resource "google_compute_address" "dev_static_ip" {
#   name = "moongsan-dev-ip"
# }

# prod VM 생성
resource "google_compute_instance" "prod_vm" {
  name         = "moongsan-prod-vm"
  machine_type = var.vm_machine_type
  zone         = "asia-northeast3-a"

  boot_disk {
    initialize_params {
      image = var.ubuntu_image
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.prod_static_ip.address
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx mysql-server python3-pip openjdk-17-jdk
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    apt-get install -y nodejs
    pip3 install fastapi uvicorn
  EOT

  tags = ["prod"]
}

# # dev VM 생성
# resource "google_compute_instance" "dev_vm" {
#   name         = "moongsan-dev-vm"
#   machine_type = var.vm_machine_type
#   zone         = "asia-northeast3-a"

#   boot_disk {
#     initialize_params {
#       image = var.ubuntu_image
#     }
#   }

#   network_interface {
#     network = "default"
#     access_config {
#       nat_ip = google_compute_address.dev_static_ip.address
#     }
#   }

#   metadata = {
#     ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
#   }

#   metadata_startup_script = <<-EOT
#     #!/bin/bash
#     apt-get update -y
#     apt-get install -y nginx mysql-server python3-pip openjdk-17-jdk
#     curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
#     apt-get install -y nodejs
#     pip3 install fastapi uvicorn
#   EOT

#   tags = ["dev"]
# }

# 방화벽 설정
resource "google_compute_firewall" "allow-web-traffic" {
  name    = "allow-web-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["prod"]
  # target_tags = ["prod", "dev"]
}


provider "google" {
  credentials = file("/Users/lsh/workspace/downloads/keys/ktb-2-moongsan-d9d52232b71b.json")
  project = var.project_id
  region  = "asia-northeast3"
  zone    = "asia-northeast3-a"
}

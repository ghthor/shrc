plugin "nomad-device-nvidia" {
  config {
    enabled            = true
    ignored_gpu_ids    = []
    fingerprint_period = "1m"
  }
}

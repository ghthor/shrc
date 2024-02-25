# state directory
data_dir = "/var/lib/nomad"

# binaries shouldn't go in /var/lib
plugin_dir = "/usr/lib/nomad/plugins"

bind_addr = "0.0.0.0"

datacenter = "ghthor"

# Enable the server
server {
  enabled              = true
  authoritative_region = "global"
  bootstrap_expect     = 1
}

# Enable the client
client {
  enabled = true

  # https://www.nomadproject.io/docs/v0.11.8/configuration/client#reserved-parameters
  reserved {
    cpu    = 1024
    memory = 2048
    disk   = 2048

    // ssh port and consul/nomad ports
    reserved_ports = "22,8500-8600"
  }

  # host_volume "voltus_monorepo" {
  #   path      = "/home/ghthor/.voltus/voltus"
  #   read_only = true
  # }
}

plugin "raw_exec" {
  config {
    enabled = false
  }
}

plugin "docker" {
  config {
    # TODO(will): should be set to false once all host volumes are defined in config
    #             and are updated and deployed in the job specifications
    volumes {
      enabled = true
    }

    # auth {
    #   config = "/home/ubuntu/.docker/config.json"
    # }

    allow_caps       = ["NET_ADMIN"]
    allow_privileged = true
  }
}

# TODO(will)
#   yay -S nomad-device-nvidia-bin # works
#   yay -S nomad-device-nvidia     # locally compiled fails
plugin "nomad-device-nvidia" {
  config {
    enabled            = true
    ignored_gpu_ids    = []
    fingerprint_period = "1m"
  }
}

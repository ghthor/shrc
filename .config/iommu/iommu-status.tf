variable "root_write" {
  default = false
}

locals {
  boot_with_iommu = true

  root_disk = "root=/dev/disk/by-uuid/547f179c-c3c6-4101-8c75-24c644cdcf85"

  nvme_ssd   = "144d:a804"
  usb3_ctl   = "1912:0014"
  vega_gpu   = "1002:687f"
  vega_audio = "1002:aaf8"

  vfio_pci_ids = "${join(",", list(
local.nvme_ssd,
local.usb3_ctl,
local.vega_gpu,
local.vega_audio,
))}"

  cmdline_iommu_off = "${local.root_disk} rw vsyscall=emulate amd_iommu=off"
  cmdline_iommu_on  = "${local.root_disk} rw vsyscall=emulate amd_iommu=on iommu=pt vfio-pci.ids=${local.vfio_pci_ids}"

  path_syslinux_cfg = "boot/syslinux/syslinux.cfg"
}

data "template_file" "syslinux_cfg_iommu_off" {
  count    = "${local.boot_with_iommu ? 0 : 1}"
  template = "${file("${path.module}/${local.path_syslinux_cfg}.tpl")}"

  vars {
    label   = "Arch Linux (IOMMU Disabled)"
    cmdline = "${local.cmdline_iommu_off}"
  }
}

data "template_file" "syslinux_cfg_iommu_on" {
  count    = "${local.boot_with_iommu ? 1 : 0}"
  template = "${file("${path.module}/${local.path_syslinux_cfg}.tpl")}"

  vars {
    label   = "Arch Linux (IOMMU Enabled)"
    cmdline = "${local.cmdline_iommu_on}"
  }
}

resource "local_file" "syslinux_cfg" {
  filename = "${path.module}/${local.path_syslinux_cfg}"

  content = "${element(coalescelist(
data.template_file.syslinux_cfg_iommu_off.*.rendered,
data.template_file.syslinux_cfg_iommu_on.*.rendered), 0)}"
}

resource "local_file" "root_terraform_apply_sh" {
  filename = "${path.module}/root_terraform_apply.sh"

  content = <<EOF
#!/bin/bash

set -xeuo pipefail

export TF_VAR_root_write="false"
terraform plan

export TF_VAR_root_write="true"
terraform apply

EOF
}

resource "null_resource" "root_write" {
  count = "${var.root_write ? 1 : 0}"

  triggers {
    syslinux_cfg_changed = "${local_file.syslinux_cfg.id}"
  }

  provisioner "local-exec" {
    command = "sudo cp ${local_file.syslinux_cfg.filename} /${local.path_syslinux_cfg}"
  }
}

output "iommu_enabled" {
  value = "${local.boot_with_iommu}"
}

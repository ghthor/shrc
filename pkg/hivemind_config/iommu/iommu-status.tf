terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

variable "root_write" {
  default = false
}

locals {
  boot_with_iommu = true

  root_disk = "root=/dev/disk/by-uuid/547f179c-c3c6-4101-8c75-24c644cdcf85"

  vega_gpu   = "1002:687f"
  vega_audio = "1002:aaf8"
  nvme_ssd   = "144d:a804"
  usb_card   = "1912:0014"

  hugepages = "default_hugepagesz=1G hugepagesz=1G hugepages=16"

  cmdline_iommu_off = "${local.root_disk} rw amd_iommu=off vsyscall=emulate"
  cmdline_iommu_on  = "${local.root_disk} rw amd_iommu=on iommu=pt kvm.ignore_msrs=1 vsyscall=emulate ${local.hugepages}"

  path_modprobe_conf   = "etc/modprobe.d/vfio.conf"
  path_mkinitcpio_conf = "etc/mkinitcpio.conf"
  path_syslinux_cfg    = "boot/syslinux/syslinux.cfg"
}

locals {
  syslinux_cfg_iommu_off = templatefile("${path.module}/${local.path_syslinux_cfg}.tpl", {
    label   = "Arch Linux (IOMMU Disabled)"
    cmdline = local.cmdline_iommu_off
  })

  syslinux_cfg_iommu_on = templatefile("${path.module}/${local.path_syslinux_cfg}.tpl", {
    label   = "Arch Linux (IOMMU Enabled)"
    cmdline = local.cmdline_iommu_on
  })
}

resource "local_file" "modprobe_conf" {
  count    = local.boot_with_iommu ? 1 : 0
  filename = "${path.module}/${local.path_modprobe_conf}"

  content = <<EOF
options vfio-pci ids=${local.vega_gpu},${local.vega_audio},${local.nvme_ssd},${local.usb_card}
options kvm_amd avic=1
EOF
}

locals {
  mkinitcpio_conf = templatefile("${path.module}/${local.path_mkinitcpio_conf}.tpl", {})
}

resource "local_file" "mkinitcpio_conf" {
  filename = "${path.module}/${local.path_mkinitcpio_conf}"
  content  = local.mkinitcpio_conf
}

resource "local_file" "syslinux_cfg" {
  filename = "${path.module}/${local.path_syslinux_cfg}"
  content  = local.boot_with_iommu ? local.syslinux_cfg_iommu_on : local.syslinux_cfg_iommu_off
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
  count = var.root_write ? 1 : 0

  triggers = {
    mkinitcpio_conf_changed = local_file.mkinitcpio_conf.id
    syslinux_cfg_changed    = local_file.syslinux_cfg.id
  }

  provisioner "local-exec" {
    command = "sudo rsync ${path.module}/${local.path_modprobe_conf} /${local.path_modprobe_conf}"
  }

  provisioner "local-exec" {
    command = "sudo cp ${local_file.mkinitcpio_conf.filename} /${local.path_mkinitcpio_conf}"
  }

  provisioner "local-exec" {
    command = "sudo cp ${local_file.syslinux_cfg.filename} /${local.path_syslinux_cfg}"
  }

  provisioner "local-exec" {
    command = "sudo mkinitcpio -p linux"
  }
}

output "iommu_enabled" {
  value = local.boot_with_iommu
}

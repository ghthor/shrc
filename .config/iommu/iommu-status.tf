variable "root_write" {
  default = false
}

locals {
  boot_with_iommu = true

  root_disk = "root=/dev/disk/by-uuid/547f179c-c3c6-4101-8c75-24c644cdcf85"

  cmdline_iommu_off = "${local.root_disk} rw amd_iommu=off vsyscall=emulate"
  cmdline_iommu_on  = "${local.root_disk} rw amd_iommu=on iommu=pt vsyscall=emulate"
}

data "template_file" "syslinux_cfg_iommu_off" {
  count    = "${local.boot_with_iommu ? 0 : 1}"
  template = "${file("${path.module}/boot/syslinux/syslinux.cfg.tpl")}"

  vars {
    label   = "Arch Linux (IOMMU Disabled)"
    cmdline = "${local.cmdline_iommu_off}"
  }
}

data "template_file" "syslinux_cfg_iommu_on" {
  count    = "${local.boot_with_iommu ? 1 : 0}"
  template = "${file("${path.module}/boot/syslinux/syslinux.cfg.tpl")}"

  vars {
    label   = "Arch Linux (IOMMU Enabled)"
    cmdline = "${local.cmdline_iommu_on}"
  }
}

resource "local_file" "modprobe_conf" {
  count    = "${local.boot_with_iommu ? 1 : 0}"
  filename = "${path.module}/etc/modprobe.d/vfio.conf"

  content = <<EOF
options vfio-pci ids=1002:687f,1002:aaf8,144d:a804
options kvm_amd avic=1
EOF
}

resource "local_file" "syslinux_cfg" {
  filename = "${path.module}/boot/syslinux/syslinux.cfg"

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

  provisioner "local-exec" {
    command = "sudo rsync --delete-missing-args ${local_file.modprobe_conf.filename} /etc/modprobe.d/vfio.conf"
  }

  provisioner "local-exec" {
    command = "sudo cp ${local_file.syslinux_cfg.filename} /boot/syslinux/syslinux.cfg"
  }
}

output "iommu_enabled" {
  value = "${local.boot_with_iommu}"
}

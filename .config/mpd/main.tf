terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

variable "icecast_admin_user" {}

variable "icecast_admin_email" {}

resource "local_file" "gitignore" {
  filename = "${path.module}/.gitignore"

  content = <<EOF
.terraform
*.tfstate
*.tfstate.backup
icecast.xml
mpd.conf
*passwd
EOF
}

locals {
  mpd_passwd    = "${path.module}/mpd_passwd"
  admin_passwd  = "${path.module}/admin_passwd"
  relay_passwd  = "${path.module}/relay_passwd"
  source_passwd = "${path.module}/source_passwd"
}

resource "null_resource" "pwgen" {
  provisioner "local-exec" {
    command = "pwgen -c0B 30 -N 1 > ${local.mpd_passwd}"
  }

  provisioner "local-exec" {
    command = "pwgen -s 100 -N 1 > ${local.admin_passwd}"
  }

  provisioner "local-exec" {
    command = "pwgen -s 100 -N 1 > ${local.relay_passwd}"
  }

  provisioner "local-exec" {
    command = "pwgen -s 100 -N 1 > ${local.source_passwd}"
  }
}

data "null_data_source" "pwgen" {
  inputs = {
    gen_id = "${null_resource.pwgen.id}"
    mpd    = "${local.mpd_passwd}"
    admin  = "${local.admin_passwd}"
    relay  = "${local.relay_passwd}"
    source = "${local.source_passwd}"
  }
}

data "local_file" "mpd_passwd" {
  filename = "${data.null_data_source.pwgen.outputs["mpd"]}"
}

data "local_file" "admin_passwd" {
  filename = "${data.null_data_source.pwgen.outputs["admin"]}"
}

data "local_file" "relay_passwd" {
  filename = "${data.null_data_source.pwgen.outputs["relay"]}"
}

data "local_file" "source_passwd" {
  filename = "${data.null_data_source.pwgen.outputs["source"]}"
}

data "template_file" "icecast" {
  template = "${file("${path.module}/tpl_icecast.xml")}"

  vars {
    icecast_admin_email     = "${chomp(var.icecast_admin_email)}"
    icecast_admin_user      = "${chomp(var.icecast_admin_user)}"
    icecast_admin_password  = "${chomp(data.local_file.admin_passwd.content)}"
    icecast_relay_password  = "${chomp(data.local_file.relay_passwd.content)}"
    icecast_source_password = "${chomp(data.local_file.source_passwd.content)}"
  }
}

data "template_file" "mpdconf" {
  template = "${file("${path.module}/tpl_mpd.conf")}"

  vars {
    mpd_admin_password      = "${chomp(data.local_file.mpd_passwd.content)}"
    icecast_source_password = "${chomp(data.local_file.source_passwd.content)}"
  }
}

resource "local_file" "icecast_xml" {
  filename = "${path.module}/icecast.xml"
  content  = "${data.template_file.icecast.rendered}"
}

resource "local_file" "mpd_conf" {
  filename = "${path.module}/mpd.conf"
  content  = "${data.template_file.mpdconf.rendered}"
}

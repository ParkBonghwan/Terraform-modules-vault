resource "terraform_data" "ssh_file_copy" {
  count = var.create ? 1 : 0

  triggers_replace = {
    buildtime = timestamp()
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.server_user
    password    = ""
    private_key = file(var.private_key_local_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf ${var.private_file_remote_path}  >/dev/null"
    ]
  }

  provisioner "file" {
    source      = var.private_file_local_path
    destination = var.private_file_remote_path
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod ${var.permissions} ${var.private_file_remote_path}"
    ]
  }
}
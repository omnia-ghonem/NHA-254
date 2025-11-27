resource "ansible_host" "ansible_hosts_master" {
  depends_on = [ aws_instance.master ]
  name   = "control_node"
  groups = ["masters"]

  variables = {
    ansible_user = "ec2-user"
    ansible_host = aws_instance.master.public_ip
    ansible_ssh_private_key_file = var.private_key_path
    node_hostname = "master"
  }
}


resource "ansible_host" "ansible_hosts_workers" {
    depends_on = [ aws_instance.worker ]

    count = var.worker_count
    name = "worker_node_${count.index + 1}"
    groups = ["workers"]
    variables = {
      ansible_user = "ec2-user"
      ansible_host = aws_instance.worker[count.index].public_ip
      ansible_ssh_private_key_file = var.private_key_path
      node_hostname = "worker-${count.index + 1}"
    }

}
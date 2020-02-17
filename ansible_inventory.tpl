[heartbeat_group]
${primary} droplet_id=${primary_droplet_id} hostname=${primary_name}
${secondary} droplet_id=${secondary_droplet_id} hostname=${secondary_name}

[floating_ip]
${floating_ip}

[heartbeat_group:vars]
floating_ip=${floating_ip}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[all:vars]
ansible_python_interpreter=/usr/bin/python3

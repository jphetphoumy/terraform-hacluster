[heartbeat_group]
${primary} droplet_id=${primary_droplet_id}
${secondary} droplet_id=${secondary_droplet_id}

[heartbeat_group:vars]
floating_ip=${floating_ip}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

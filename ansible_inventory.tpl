[heartbeat_group]
${primary} 
${secondary}

[heartbeat_group:vars]
floating_ip=${floating_ip}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
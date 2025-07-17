all:
  hosts:
%{ for vm in vms ~}
    ${vm.name}:
      ansible_host: ${vm.ipv4_addresses[1][0]}
      ansible_user: ubuntu
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
%{ endfor ~}
  vars:
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_become_password: ubuntu

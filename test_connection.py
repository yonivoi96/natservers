import subprocess
import paramiko
import json
import os

server_ips = subprocess.check_output(["terraform", "output", "-json"])
outputs = json.loads(server_ips)

seed_private_ip = outputs["private_ips"]["value"][0]
other_private_ips = outputs["private_ips"]["value"][1:]

seed_public_ip = outputs["public_ips"]["value"][0]
other_public_ips = outputs["public_ips"]["value"][1:]

ssh_key_pair = "tf-key-pair"
ssh_user = "ec2-user"
os.chmod(ssh_key_pair, 0o400)

def run_nats_servers(server_private_ip, server_public_ip):
    try:
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(server_public_ip, username=ssh_user, key_filename=ssh_key_pair)

        log_file_path = "nats.log"
        if server_private_ip == seed_private_ip:
            ssh_client.exec_command(f"nats-server -p 4222 -cluster nats://{seed_private_ip}:4248 --cluster_name nats-cluster -l {log_file_path}")
        else:
            ssh_client.exec_command(f"nats-server -p 6222 -cluster nats://{server_private_ip}:5248 -routes nats://{seed_private_ip}:4248 --cluster_name nats-cluster -l {log_file_path}")

        ssh_client.close()

    except Exception as e:
        print(f"Error configuring Nats-server on {server_public_ip}: {str(e)}")


def check_logs(server_public_ip):
    try:
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(server_public_ip, username=ssh_user, key_filename=ssh_key_pair)

        log_file_path = "nats.log"
        stdin, stdout, stderr = ssh_client.exec_command(f"cat {log_file_path}")
        output = stdout.read().decode()
        if "ERR" not in output:
            print(f"Successfully configured NATS on {server_public_ip} with the seed server")
        else:
            print(f"Error configuring NATS on {server_public_ip}: Unable to establish communication with the seed server")
        ssh_client.close()
    except Exception as e:
        print(f"Error checking logs on {server_public_ip}: {str(e)}")

run_nats_servers(seed_private_ip, seed_public_ip)

for private_ip, public_ip in zip(other_private_ips, other_public_ips):
    run_nats_servers(private_ip, public_ip)

for public_ip in other_public_ips:
    check_logs(public_ip)

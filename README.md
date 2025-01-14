Take a look on this **readme** file for this task

# Docker Isolated Networking Setup with Network Namespaces and iptables

This project provides a solution to set up isolated networking environments using Docker, Linux network namespaces, and `iptables`. The goal is to simulate two isolated environments (e.g., "Team A" and "Team B") that can be selectively allowed to communicate via a bridge network.

## Requirements

- Docker installed on a Linux system
- `iptables` installed for network configuration

## Features

1. Creates two Docker containers simulating isolated environments (Team A and Team B).
2. Uses Linux network namespaces to isolate the containers.
3. Sets up a bridge network for selective communication between containers.
4. Uses `iptables` to control and restrict communication between containers.
5. Provides a script to automate the entire setup process.

## Installation & Setup

### 1. Install Docker (if not installed)

Ensure Docker is installed on your system. Follow these commands for installation:

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y docker.io
FIRSTLY
Create 2 container all together with the network using the command 
    docker run -d –name TEAM_A  --network team_A_network nginx
    docker run -d –name TEAM_B  --network team_B_network nginx
   we then create   a bridged network to allow controlled communication between the container
    sudo ip link add br0 type bridge
    sudo ip addr add 192.168.1.1/24 dev br0
    sudo ip link set br0 up
 we now create 2 pairs of virtual ethernet  (veth)
    sudo ip link add veth0 type veth peer name veth1
    sudo ip link add veth2 type veth peer name veth3
 we then attach one end of each veth pair to the bridge
    sudo ip link set veth0 master br0
    sudo ip link set veth2 master br0
    sudo ip link set veth0 up
    sudo ip link set veth2 up
 then the other end of the each veth is then attached to the container
    sudo ip link set veth1 netns $(docker inspect -f '{{.State.Pid}}' team_a)
    sudo ip link set veth3 netns $(docker inspect -f '{{.State.Pid}}' team_b)

 then we configure the ip addresses of the containers
      sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' team_a) -n ip addr add 192.168.1.2/24 dev veth1
    sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' team_a) -n ip link set veth1 up
    sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' team_b) -n ip addr add 192.168.1.3/24 dev veth3
    sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' team_b) -n ip link set veth3 up

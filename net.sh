#!/bin/bash

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo or as root."
  exit 1
fi

# Step 1: Clean up any existing containers and networks
echo "Cleaning up existing resources..."
docker stop team_a_container team_b_container 2>/dev/null
docker rm team_a_container team_b_container 2>/dev/null
docker network rm isolated_network 2>/dev/null
sudo ip link delete br0 2>/dev/null
sudo ip link delete veth1 2>/dev/null
sudo ip link delete veth2 2>/dev/null
echo "Cleanup completed."

# Step 2: Create Docker containers for Team A and Team B
echo "Creating Docker containers for Team A and Team B..."
docker network create isolated_network 2>/dev/null || echo "Network 'isolated_network' already exists."
docker run -d --name team_a_container --network isolated_network ubuntu bash -c "while true; do sleep 1; done;" 2>/dev/null || echo "Container 'team_a_container' already exists."
docker run -d --name team_b_container --network isolated_network ubuntu bash -c "while true; do sleep 1; done;" 2>/dev/null || echo "Container 'team_b_container' already exists."
echo "Docker containers 'team_a_container' and 'team_b_container' are created."

# Step 3: Set up a bridged network on the host
echo "Setting up a bridge network (br0) on the host..."
sudo ip link add name br0 type bridge 2>/dev/null || echo "Bridge 'br0' already exists."
sudo ip addr add 192.168.100.1/24 dev br0 2>/dev/null || echo "IP address already assigned to 'br0'."
sudo ip link set br0 up 2>/dev/null || echo "Bridge 'br0' is already up."
echo "Bridge 'br0' configured successfully."

# Step 4: Create veth pairs for communication between containers and bridge
echo "Creating virtual Ethernet (veth) pairs for communication between containers and bridge..."
sudo ip link add veth1 type veth peer name veth1_br 2>/dev/null || echo "Veth pair 'veth1/veth1_br' already exists."
sudo ip link add veth2 type veth peer name veth2_br 2>/dev/null || echo "Veth pair 'veth2/veth2_br' already exists."
sudo ip link set veth1_br master br0 2>/dev/null || echo "Veth1_br already attached to the bridge."
sudo ip link set veth2_br master br0 2>/dev/null || echo "Veth2_br already attached to the bridge."
sudo ip link set veth1 up 2>/dev/null || echo "Veth1 is already up."
sudo ip link set veth2 up 2>/dev/null || echo "Veth2 is already up."
echo "Veth pairs and bridge connection established."

# Step 5: Attach veth pairs to the Docker containers
echo "Attaching veth pairs to the Docker containers..."
TEAM_A_PID=$(docker inspect -f '{{.State.Pid}}' team_a_container 2>/dev/null)
TEAM_B_PID=$(docker inspect -f '{{.State.Pid}}' team_b_container 2>/dev/null)

if [ -z "$TEAM_A_PID" ]; then
  echo "Error: Could not retrieve PID for Team A container. Is it running?"
  exit 1
fi

if [ -z "$TEAM_B_PID" ]; then
  echo "Error: Could not retrieve PID for Team B container. Is it running?"
  exit 1
fi

# Move veth interfaces into the container namespaces
sudo ip link set veth1 netns $TEAM_A_PID 2>/dev/null || echo "Veth1 already attached to Team A."
sudo ip link set veth2 netns $TEAM_B_PID 2>/dev/null || echo "Veth2 already attached to Team B."
echo "Veth pairs successfully attached to containers."

# Step 6: Retrieve the Docker-assigned IP addresses for Team A and Team B
TEAM_A_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' team_a_container)
TEAM_B_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' team_b_container)

if [ -z "$TEAM_A_IP" ]; then
  echo "Error: Could not retrieve IP address for Team A container."
  exit 1
fi

if [ -z "$TEAM_B_IP" ]; then
  echo "Error: Could not retrieve IP address for Team B container."
  exit 1
fi

echo "Team A IP: $TEAM_A_IP"
echo "Team B IP: $TEAM_B_IP"

# Step 7: Set up iptables for communication restrictions
echo "Setting up iptables rules for communication restrictions..."
# Allow Team A to communicate with Team B
sudo nsenter -t $TEAM_A_PID -n iptables -A OUTPUT -d $TEAM_B_IP -p icmp --icmp-type echo-request -j ACCEPT
sudo nsenter -t $TEAM_B_PID -n iptables -A INPUT -s $TEAM_A_IP -p icmp --icmp-type echo-request -j ACCEPT

# Block Team B from communicating with Team A
sudo nsenter -t $TEAM_B_PID -n iptables -A OUTPUT -d $TEAM_A_IP -p icmp --icmp-type echo-request -j REJECT
sudo nsenter -t $TEAM_A_PID -n iptables -A INPUT -s $TEAM_B_IP -p icmp --icmp-type echo-request -j REJECT
echo "iptables rules configured."

# Step 8: Test connectivity between containers
echo "Testing connectivity..."
# Test ping from Team A to Team B
echo "Pinging Team B from Team A..."
sudo nsenter -t $TEAM_A_PID -n ping -c 4 $TEAM_B_IP

# Test ping from Team B to Team A
echo "Pinging Team A from Team B..."
sudo nsenter -t $TEAM_B_PID -n ping -c 4 $TEAM_A_IP

echo "Setup completed successfully!"

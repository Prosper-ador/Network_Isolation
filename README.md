Take a look on this **readme** file that explains the process, setup, and usage of the script and Docker containers for this task.
# *Group members for exercise 3*  
-*Nafisatou  Hamadou*  
-*Louisa Mbiti*  
-*Nyengka Prosper*  
---

# **Docker Networking with Network Namespaces and IP Tables**

This task demonstrates how to create isolated networking environments for Docker containers using network namespaces and `iptables`. The containers will simulate two teams (Team A and Team B), each with their respective isolated networking environments. We'll use Docker, Linux networking tools, and `iptables` to ensure network isolation and selective communication.

## **Project Overview**

- **Team A** and **Team B** are created as Docker containers.
- Containers are attached to an isolated Docker network, ensuring they start with dynamic IPs assigned by Docker.
- Virtual Ethernet pairs (`veth`) are created and connected to the host’s bridge network (`br0`).
- Network namespaces are used to enforce isolation between the two containers.
- `iptables` is configured to allow selective communication. In this setup:
  - **Team A** can communicate with **Team B**.
  - **Team B** cannot communicate with **Team A** (one-way communication).

---

## **Project Structure**

- **Dockerfile**: Builds the Docker image for both Team A and Team B.
- **setup_isolated_network.sh**: A Bash script to automate the entire setup process, including container creation, network configuration, and `iptables` setup.
- **README.md**: Project documentation (this file).

---

## **Prerequisites**

Before running this project, ensure you have the following installed:

- **Docker**: To build and run the containers.
- **Linux (Ubuntu or similar)**: The script is designed to work on Linux systems.
- **Root (sudo) privileges**: The script requires root access for setting up network configurations.
- **iproute2 & iptables**: These are necessary tools for managing network namespaces and configuring firewall rules.

To install Docker on Ubuntu, run:

```bash
sudo apt update
sudo apt install docker.io
```

To install `iproute2` and `iptables`:

```bash
sudo apt-get update
sudo apt-get install iproute2 iptables
```

---

## **How to Build and Run**

### **1. Build the Docker Images for Team A and Team B**

1. Clone this repository or download the project files to your local machine.
2. Open a terminal and navigate to the project directory.
3. Build the Docker images for Team A and Team B using the Dockerfile.

```bash
# Build the image for Team A
docker build --build-arg TEAM_NAME="Team A" -t team_a .

# Build the image for Team B
docker build --build-arg TEAM_NAME="Team B" -t team_b .
```

This will create two Docker images (`team_a` and `team_b`), each configured with basic networking tools like `ping`, `curl`, and `iptables`.

### **2. Run the Setup Script**

Once the Docker images are built, you can run the setup script to configure the network, create the containers, and set up the `iptables` rules.

1. Make sure the script is executable:
   ```bash
   chmod +x net.sh
   ```

2. Run the script with `sudo`:
   ```bash
   sudo ./net.sh
   ```

### **What the Script Does:**

- **Cleans Up Existing Resources**: The script stops and removes any pre-existing containers, networks, or interfaces.
- **Creates Docker Containers**: It creates two Docker containers (`team_a_container` and `team_b_container`), each running an Ubuntu container.
- **Sets Up a Host Bridge Network (`br0`)**: This is a network bridge on the host machine that connects the containers to the host network.
- **Creates Virtual Ethernet Pairs**: Virtual Ethernet devices (`veth1`, `veth2`) are created to bridge the Docker containers to the host network.
- **Attaches veth Pairs to Containers**: The veth interfaces are moved into the container namespaces to link them with the host bridge.
- **Assigns Dynamic IPs**: The script retrieves Docker-assigned IP addresses for the containers using `docker inspect`.
- **Configures `iptables`**: The script configures `iptables` to ensure Team A can communicate with Team B, but Team B cannot communicate with Team A (one-way communication).
- **Tests Connectivity**: Finally, it runs ping or curl tests to ensure the network isolation and communication restrictions are working as expected.

---

## **Testing the Setup**

After running the script, the following tests are conducted:

- **Team A Ping Test**: The script pings Team B from Team A.
- **Team B Ping Test**: The script attempts to ping Team A from Team B, which should fail due to the `iptables` rule that blocks Team B from accessing Team A.

If everything is configured correctly:

- Team A will be able to ping Team B (`ping` test from Team A to Team B will succeed).
- Team B will NOT be able to ping Team A (`ping` test from Team B to Team A will fail).

### **Note:**
- **Team A to Team B Ping**: Will succeed, as `iptables` allows it.
- **Team B to Team A Ping**: Will fail, as `iptables` blocks Team B from reaching Team A.

---

## **Customization**

- **Network Isolation**: You can modify the `iptables` rules to change the communication behavior between the containers. For instance, you could allow two-way communication or block specific ports.
- **Dynamic IP Addresses**: The script dynamically retrieves the IP addresses assigned by Docker, so no changes are needed if IPs change upon restarting the containers.
  
You can also customize the IP ranges, container names, or network settings by adjusting the script and Dockerfile.

---

## **Troubleshooting**

- **Docker Network Issues**: Ensure Docker is running and configured properly. You can check Docker network status using:
  ```bash
  docker network ls
  ```

- **Permissions**: If you encounter permissions issues, ensure the script is run with `sudo` or as the root user.

---

## **Conclusion**

This task demonstrates how to isolate Docker containers into separate network namespaces and use `iptables` to enforce communication restrictions. By automating the setup with a script, we make it easier for all steps to be executed in an instance of time. For more updates collaborations will be welcomed.

---


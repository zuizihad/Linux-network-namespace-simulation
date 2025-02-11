#!/bin/bash

# Define network namespaces
NS1=ns1
NS2=ns2
ROUTER=router_ns
BR0=br0
BR1=br1

VETHNS1=veth-ns1
VETHNS1BR0=veth-ns1-br0

VETHNS2=veth-ns2
VETHNS2BR1=veth-ns2-br1

VETHR1=vethr1
VETHR1BR0=vethr1-br0

VETHR2=vethr2
VETHR2BR1=vethr2-br1

# Create network namespaces
sudo ip netns add $NS1
sudo ip netns add $NS2
sudo ip netns add $ROUTER

# Create bridges
sudo ip link add name $BR0 type bridge
sudo ip link add name $BR1 type bridge

# Create veth pairs
sudo ip link add $VETHNS1 type veth peer name $VETHNS1BR0
sudo ip link add $VETHNS2 type veth peer name $VETHNS2BR1
sudo ip link add $VETHR1 type veth peer name $VETHR1BR0
sudo ip link add $VETHR2 type veth peer name $VETHR2BR1

# Attach veth interfaces to namespaces
sudo ip link set $VETHNS1 netns $NS1
sudo ip link set $VETHNS2 netns $NS2
sudo ip link set $VETHR1 netns $ROUTER
sudo ip link set $VETHR2 netns $ROUTER

# Attach veth interfaces to bridges
sudo ip link set $VETHNS1BR0 master $BR0
sudo ip link set $VETHNS2BR1 master $BR1
sudo ip link set $VETHR1BR0 master $BR0
sudo ip link set $VETHR2BR1 master $BR1

# Assign IP addresses to the bridges
sudo ip addr add 10.11.0.3/24 dev $BR0
sudo ip addr add 10.12.0.3/24 dev $BR1

# Bring up the bridges and its interfaces
sudo ip link set $BR0 up
sudo ip link set $BR1 up
sudo ip link set $VETHNS1BR0 up
sudo ip link set $VETHNS2BR1 up
sudo ip link set $VETHR1BR0 up
sudo ip link set $VETHR2BR1 up

# Assign IP addresses to the namespaces
sudo ip netns exec $NS1 ip addr add 10.11.0.2/24 dev $VETHNS1
sudo ip netns exec $NS2 ip addr add 10.12.0.2/24 dev $VETHNS2
sudo ip netns exec $ROUTER ip addr add 10.11.0.1/24 dev $VETHR1
sudo ip netns exec $ROUTER ip addr add 10.12.0.1/24 dev $VETHR2

# Bring up the veth interfaces inside namespaces
sudo ip netns exec $NS1 ip link set $VETHNS1 up
sudo ip netns exec $NS2 ip link set $VETHNS2 up
sudo ip netns exec $ROUTER ip link set $VETHR1 up
sudo ip netns exec $ROUTER ip link set $VETHR2 up

# Enable IP forwarding in the router
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Set up default routes
sudo ip netns exec $NS1 ip route add default via 10.11.0.1
sudo ip netns exec $NS2 ip route add default via 10.12.0.1

# Configure firewall rules for forwarding
sudo iptables --append FORWARD --in-interface $BR0 --jump ACCEPT
sudo iptables --append FORWARD --out-interface $BR0 --jump ACCEPT
sudo iptables --append FORWARD --in-interface $BR1 --jump ACCEPT
sudo iptables --append FORWARD --out-interface $BR1 --jump ACCEPT

# Enable NAT
sudo iptables -t nat -A POSTROUTING -o $BR0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -o $BR1 -j MASQUERADE

# Test connectivity
sudo ip netns exec $NS2 ping -c 3 10.11.0.1


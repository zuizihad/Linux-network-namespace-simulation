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


# Cleanup function
cleanup() {
    ip netns del $NS1 || true
    ip netns del $NS2 || true
    ip netns del $ROUTER || true
    ip link del $BR0 || true
    ip link del $BR1 || true
    ip link del $VETHNS1 || true
    ip link del $VETHNS1BR0 || true
    ip link del $VETHNS2 || true
    ip link del $VETHNS2BR1 || true
    ip link del $VETHR1 || true
    ip link del $VETHR1BR0 || true
    ip link del $VETHR2 || true
    ip link del $VETHR2BR1 || true
    echo "Cleanup complete."
}


# Trap exit to cleanup
trap cleanup EXIT
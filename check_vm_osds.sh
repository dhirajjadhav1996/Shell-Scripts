#!/bin/bash

POOL_NAME="ceph-vm-pool"  # Change this to your Ceph pool name

# Get a list of all VM disks
VM_DISKS=$(rbd list -p $POOL_NAME)

echo "Checking OSDs for containers in pool: $POOL_NAME"
echo "----------------------------------------"

# Loop through each VM disk
for VM_DISK in $VM_DISKS; do
    echo "RBD Image: $VM_DISK"

    # Get all objects related to this VM disk
    OBJECTS=$(rados -p $POOL_NAME ls | grep "$VM_DISK")

    # Loop through each object to find its OSD placement
    for OBJECT in $OBJECTS; do
        # Get the OSD map for the object
        OSD_INFO=$(ceph osd map $POOL_NAME $OBJECT)

        echo "  Object: $OBJECT"
        echo "  OSD Map Info: $OSD_INFO"

        # Extracting the PG from the OSD map output
        PG=$(echo "$OSD_INFO" | grep -oP 'pg \S+' | awk '{print $2}')

        # Extract PG ID and PG Hash from PG
        PG_ID=$(echo "$PG" | awk -F'.' '{print $1}')
        PG_HASH=$(echo "$PG" | awk -F'.' '{print $2}')

        # Proper extraction of OSDs
        OSD_LIST=$(echo "$OSD_INFO" | grep -oP 'up \([^\)]+' | sed 's/up (\(.*\))/\1/' | tr -d ' ')

        # Output the information
        echo "  PG: $PG_ID.$PG_HASH"
        echo "  OSDs: $OSD_LIST"
    done

    echo "----------------------------------------"
done

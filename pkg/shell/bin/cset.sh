#!/usr/bin/env bash

#
# Original author: Rokas Kupstys <rokups@zoho.com>
# Heavily modified by: Danny Lin <danny@kdrag0n.dev>
# Customized by: Will Walthall <ghthor@gmail.com>
#
# This hook uses the systemctl slice property AllowedCPUs
# to dynamically isolate and unisolate CPUs using
# the kernel's cgroup cpusets feature. While it's not as effective as
# full kernel-level scheduler and timekeeping isolation, it still does wonders
# for VM latency as compared to not isolating CPUs at all. Note that vCPU thread
# affinity is a must for this to work properly.
#
# Original source: https://rokups.github.io/#!pages/gaming-vm-performance.md
# Secondary source: https://github.com/PassthroughPOST/VFIO-Tools/blob/master/libvirt_hooks/hooks/cset.sh
# systemctl cpuset source: https://old.reddit.com/r/VFIO/comments/mihb5j/systemd248_breaks_vm_boot_libvirt/gt9nk2q/
# TODO: Maybe incorporate the Hugepages management from
# https://rokups.github.io/#!pages/gaming-vm-performance.md
#
# Target file locations:
#   - $SYSCONFDIR/hooks/qemu.d/vm_name/prepare/begin/cset.sh
#   - $SYSCONFDIR/hooks/qemu.d/vm_name/release/end/cset.sh
# $SYSCONFDIR is usually /etc/libvirt.
#

function hex_from_bin() {
  echo "obase=16; ibase=2; $1" | bc 
}

TOTAL_CORES='0-15'
TOTAL_CORES_MASK="$(hex_from_bin 1111111111111111)"
HOST_CORES='0-3,8-11'           # Cores reserved for host
HOST_CORES_MASK="$(hex_from_bin 0000111100001111)"
VIRT_CORES='4-7,12-15'          # Cores reserved for virtual machine(s)

VM_NAME="$1"
VM_ACTION="$2/$3"

function shield_vm() {
  # cset -m set -c $TOTAL_CORES -s machine.slice
  # cset -m shield --kthread on --cpu $VIRT_CORES
  for t in user system init; do
    systemctl set-property --runtime -- ${t}.slice AllowedCPUs=$HOST_CORES
  done
}

function unshield_vm() {
  # cset -m shield --reset
  for t in user system init; do
    systemctl set-property --runtime -- ${t}.slice AllowedCPUs=$TOTAL_CORES
  done
}

# For convenient manual invocation
if [[ "$VM_NAME" == "shield" ]]; then
    shield_vm
    exit
elif [[ "$VM_NAME" == "unshield" ]]; then
    unshield_vm
    exit
fi

if [[ "$VM_ACTION" == "prepare/begin" ]]; then
    echo "libvirt-qemu cset: Reserving CPUs $VIRT_CORES for VM $VM_NAME" > /dev/kmsg 2>&1
    shield_vm > /dev/kmsg 2>&1

    # Reduce VM jitter: https://www.kernel.org/doc/Documentation/kernel-per-CPU-kthreads.txt
    sysctl vm.stat_interval=120
    sysctl -w kernal.watchdog=0

    # the kernel's dirty page writeback mechanism uses kthread workers. They introduce
    # massive arbitrary latencies when doing disk writes on the host and aren't
    # migrated by cset. Restrict the workqueue to use only cpu 0.
    echo $HOST_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask
    echo 0 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully reserved CPUs $VIRT_CORES" > /dev/kmsg 2>&1
elif [[ "$VM_ACTION" == "release/end" ]]; then
    echo "libvirt-qemu cset: Releasing CPUs $VIRT_CORES from VM $VM_NAME" > /dev/kmsg 2>&1
    unshield_vm > /dev/kmsg 2>&1

    sysctl vm.stat_interval=1
    sysctl -w kernel.watchdog=1

    # Revert changes made to the writeback workqueue
    echo $TOTAL_CORES_MASK > /sys/bus/workqueue/devices/writeback/cpumask
    echo 1 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully released CPUs $VIRT_CORES" > /dev/kmsg 2>&1
fi

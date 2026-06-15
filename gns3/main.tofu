# ---------------------------------------------------------------------------
# Profile
#
# Defines the container's security and device configuration. Kept as a
# standalone resource so it can be inspected and modified independently
# of the instance — useful when iterating on kernel module or device config.
#
# Config keys explained:
#
#   security.privileged
#     Container root maps 1:1 to host root (uid 0). Required for QEMU to
#     open /dev/kvm and for ubridge to manipulate raw network interfaces.
#
#   linux.kernel_modules
#     Loaded on the HOST by Incus before the container starts. The container
#     sees them already present via the shared kernel. tun/vhost_net are
#     needed for QEMU TAP networking; ip_tables/* for GNS3 topology NAT.
#
#   raw.lxc lxc.apparmor.profile=unconfined
#     Disables AppArmor confinement. QEMU and ubridge perform operations
#     (mmap PROT_EXEC, raw socket creation) the default LXC profile denies.
#
# ---------------------------------------------------------------------------
resource "incus_profile" "gns3" {
  name        = "gns3-profile"
  description = "GNS3 server — privileged container with /dev/kvm passthrough"

  config = {
    "security.privileged"  = "true"
    "linux.kernel_modules" = "nf_tables,tun,vhost_net,kvm,kvm_amd"
    "raw.lxc"              = "lxc.apparmor.profile=unconfined"
    "limits.cpu"           = tostring(var.container_cpus)
    "limits.memory"        = var.container_memory
  }

  # Root disk
  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = "default"
      size = "50GiB"
    }
  }

  # Network interface on the Incus bridge
  device {
    name = "eth0"
    type = "nic"
    properties = {
      name    = "eth0"
      network = "incusbr0"
    }
  }

  # /dev/kvm bind-mount — gives GNS3's QEMU processes direct KVM access
  # with no nested virtualisation overhead
  device {
    name = "kvm"
    type = "unix-char"
    properties = {
      path = "/dev/kvm"
    }
  }

  # /dev/net/tun — required for QEMU TAP interface creation
  device {
    name = "tun"
    type = "unix-char"
    properties = {
      path = "/dev/net/tun"
      mode = "0666"
    }
  }

  # /dev/vhost-net
  device {
    name = "vhost-net"
    type = "unix-char"
    properties = {
      path = "/dev/vhost-net"
    }
  }
}

# ---------------------------------------------------------------------------
# Instance
#
# Uses the /cloud image variant which has cloud-init pre-installed.
# The provisioning script (gns3-provision.sh) is embedded and passed to
# cloud-init via the user-data mechanism — it runs once on first boot.
#
# cloud-init.user-data is set on the instance (not the profile) because
# cloud-init runs only on first boot and is instance-specific state.
# ---------------------------------------------------------------------------
resource "incus_instance" "gns3" {
  name        = var.container_name
  image       = var.container_image
  description = "A GNS3 Installation to play around with."
  type        = "container"

  # Only the gns3 profile — it is fully self-contained and includes root +
  # eth0, so we don't need the default profile.
  profiles = [incus_profile.gns3.name]

  # Create
  file {
    # Create the systemd service unit
    content = templatefile("${path.module}/assets/gns3.service.tftpl", {})
    target_path = "/etc/systemd/system/gns3.service"
    uid         = 0
    gid         = 0
    mode        = "0644"
  }

  file {
    content = templatefile("${path.module}/assets/gns3.conf.tftpl", {
      user = var.gns3_user
      password = var.gns3_password
    })
    target_path = "/opt/gns3/gns3.conf"
    uid         = 0
    gid         = 0
    mode        = "0644"
  }

  config = {
    "boot.autostart" = "true"
    "cloud-init.user-data" = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      provision_script = file("${path.module}/assets/provision.sh")
    })
  }

  # Port forwarding: odin:host_port → container:gns3_port
  # This is what the GNS3 GUI on heimdall connects to.
  device {
    name = "gns3proxy"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:${var.host_port}"
      connect = "tcp:127.0.0.1:${var.gns3_port}"
    }
  }

  depends_on = [incus_profile.gns3]
}

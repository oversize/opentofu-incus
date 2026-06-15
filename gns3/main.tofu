locals {
  container_name   = "gns3"
  container_image  = "images:debian/13/cloud"
  container_cpus   = 4
  container_memory = "8GiB"
  host_port        = 3080 # port to be used to the outside
  gns3_port        = 3080 # Port inside container gns3 listens on
  service_user = "gns3" # the system user created for the gns3 service
}
# ---------------------------------------------------------------------------
# Projects allow to isolate resources.
#
# A project will by default inherit features from the global default project.
# If a feature is enabled in belows config map, that means the project
# will not inherit this from the default and provide its own defition of it
# if needed.
#
# See https://linuxcontainers.org/incus/docs/main/explanation/projects/#
# ---------------------------------------------------------------------------
resource "incus_project" "gns3_project1" {
  name        = "GNS3-Lab"
  description = "My GNS3 Lab"

  # Enable
  config = {
    "features.storage.volumes" = false
    "features.images"          = false
    "features.profiles"        = false
    "features.storage.buckets" = false
  }
}


# ---------------------------------------------------------------------------
# Profiles bundle instance cofnigurations. and every project has an empty default
# profile. So the above project did create a default which i am accessing here
# through the data block
# ---------------------------------------------------------------------------
data "incus_profile" "this" {
  name = "default"
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
  name        = local.container_name
  image       = local.container_image
  description = "A GNS3 Installation to play around with."
  type        = "container"
  profiles = [data.incus_profile.this.name]
  project = incus_project.gns3_project1.name

  # See also https://linuxcontainers.org/incus/docs/main/reference/instance_options/
  config = {
    "boot.autostart" = "true"
    # Priviliged container is required for QEMU to access the /dev/kvm passtrhough
    "security.privileged"  = "true"
    # Kernel modules are loaded on Host (by incus) and presented to containers
    "linux.kernel_modules" = "nf_tables,tun,vhost_net,kvm,kvm_amd"
    #  Disable AppArmor confinement. QEMU and ubridge perform operations
    #  (mmap PROT_EXEC, raw socket creation) the default LXC profile denies
    "raw.lxc"              = "lxc.apparmor.profile=unconfined"
    "limits.cpu"           = tostring(local.container_cpus)
    "limits.memory"        = local.container_memory
    "cloud-init.user-data" = templatefile("${path.module}/assets/cloud-init.yaml.tftpl", {
      provision_script = file("${path.module}/assets/provision.sh")
    })
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

  ########
  # Instance has two nic devices. The default created bridged network
  # attached to incusbr0 which allows the incus host to access the container.
  # As well as a macvlan device that allows the container to have an ip address
  # from the outside network directly mapped to it. This eliminates the
  # need of forwarding ports for gns3 because the whole system is available
  # at that macvlan ip.
  ########

  # Network interface on the Incus bridge
  device {
    name = "eth0"
    type = "nic"
    properties = {
      name    = "eth0"
      network = "incusbr0"
    }
  }

  # The macvlan network device needs to get configured through systemd-networkd
  # and will receive an ip address from the outside dhcp.
  file {
    target_path = "/etc/systemd/network/10-lan.network"
    mode        = "0644"
    # Owner is set in provivion.sh
    content = <<-EOF
[Match]
Name=lan
[Network]
DHCP=yes
EOF
  }

  # The maclvlan interface; Uses hardcoded mac address for dhcp server that
  # the ip address will not randomly change but is the configured one.
  device {
    name = "lan"
    type = "nic"
    properties = {
      name = "lan"
      nictype ="macvlan"
      parent = "enp7s0"
      hwaddr = "10:66:6a:12:34:56"
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


  # Create Files on the instance
  file {
    # Create the systemd service unit
    content = templatefile("${path.module}/assets/gns3.service.tftpl", {
      service_user = local.service_user
    })
    target_path = "/etc/systemd/system/gns3.service"
    uid         = 0
    gid         = 0
    mode        = "0644"
  }

  # The gns3 configuration file (provided as --config flag to cli)
  # Values below are from the example config.
  file {
    content = templatefile("${path.module}/assets/gns3.conf.tftpl", {
      host = "0.0.0.0"
      port = 3080
      console_start_port_range = 4000
      console_end_port_range = 6000
      udp_start_port_range = 10000
      udp_end_port_range = 20000

    })
    target_path = "/opt/gns3/gns3.conf"
    uid         = 0
    gid         = 0
    mode        = "0644"
  }
}

#!/usr/bin/env bash
# Simple bash script that provisions the gns3 installation i wrote for incus.
# Taken from the website and some googling around.
log() { echo "provision.sh => $*"; }
tmpdir="$(mktemp -d)"
GNS_VERSION=v3.0.6

# ubridge is required to connect nodes with each other.
# ?? Does ubridge neet to be be setuid'd root for raw packet capture
#    chmod +s "$(command -v ubridge)"
#    I have read that somewhere...
install_ubridge() {
    log "Building uBridge from source"
    git clone --depth 1 https://github.com/GNS3/ubridge.git "${tmpdir}/ubridge"
    cd "${tmpdir}/ubridge" || exit
    make
    make install
    log "ubridge installed at $(command -v ubridge)"
}

# Dynamips is a CISCO Router emulator. Allows to run real Ciso OS Images
install_dynamips() {
    log "Building dynamips from source"
    git clone --depth 1 https://github.com/GNS3/dynamips.git "${tmpdir}/dynamips"
    cmake -S "${tmpdir}/dynamips" -B "${tmpdir}/dynamips/build"
    make -C "${tmpdir}/dynamips/build" install
    log "dynamips installed at $(command -v dynamips)"
}


# Virtual PC Simulator, recommended by gns3
install_vpcs() {
    log "Building vpcs from source"
    git clone --depth 1 https://github.com/GNS3/vpcs.git "${tmpdir}/vpcs"
    cd "${tmpdir}/vpcs/src" || exit
    ./mk.sh 64
    mv vpcs /usr/local/bin/
    log "vpcs installed at $(command -v vpcs)"
}

# Install gns3 by cloning the code and setting up the python venv.
# I seperated gns' code folder from the venv folder.
install_gns3() {
    log "Installing gns3 /opt/gns3/${GNS_VERSION}"
    # The code lives in /opt/gns3/CODEVERSION
    mkdir -p "/opt/gns3/${GNS_VERSION}"
    chown gns3:gns3 /opt/gns3/
    git clone https://github.com/GNS3/gns3-server "/opt/gns3/${GNS_VERSION}"
    cd "/opt/gns3/${GNS_VERSION}" || exit
    git checkout "${GNS_VERSION}"
    # But the venv lives in /opt/gns3/
    log "Create gns3 venv in /opt/gns3/"
    cd /opt/gns3/ || exit
    python3 -m venv venv
    source /opt/gns3/venv/bin/activate
    python3 -m pip install -r "/opt/gns3/${GNS_VERSION}/requirements.txt"
    python3 -m pip install "/opt/gns3/${GNS_VERSION}/"
    log "Gns3 code installed in /opt/gns3/${GNS_VERSION}"
}

# Install all the things
install_dynamips
install_ubridge
install_vpcs
install_gns3

# Enable the service; Unit was written from terraform
systemctl enable --now gns3

# Make sure systemd-network properly configures the lan network
chown systemd-network:systemd-network /etc/systemd/network/10-lan.network
systemctl restart systemd-networkd

rm -rf "${tmpdir}"

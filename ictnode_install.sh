#!/usr/bin/env bash
# This script will auto-detect the OS and Version
# It will update system packages and install Ansible and git
# Then it will clone the ict-playbook and run it.

# Ict playbook: https://github.com/nuriel77/ict-playbook
# By Nuriel Shem-Tov (https://github.com/nuriel77), December 2019
# Copyright (c) 2019 Nuriel Shem-Tov

set -o pipefail
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as user root"
   echo "Please change to root using: 'sudo su -' and re-run the script"
   exit 1
fi

export NEWT_COLORS='
window=,
'

declare -g INSTALL_OPTIONS

clear
cat <<'EOF'


                                                                   .odNMMmy:
                                                                   /MMMMMMMMMy
                                                                  `NMMMMMMMMMM:
                                                                   mMMMMMMMMMM-
                                `::-                               -dMMMMMMMN/
                    `+sys/`    sNMMMm/   /ydho`                      :oyhhs/`
                   :NMMMMMm-  -MMMMMMm  :MMMMMy  .+o/`
                   hMMMMMMMs   sNMMMm:  `dMMMN/ .NMMMm
                   -mMMMMMd.    `-:-`     .:-`  `hMMNs -syo`          .odNNmy/        `.
                    `:oso:`                       `.`  mMMM+         -NMMMMMMMy    :yNNNNh/
                       `--.      :ydmh/    `:/:`       -os+`/s+`     sMMMMMMMMM`  +MMMMMMMMs
                     .hNNNNd/   /MMMMMM+  :mMMMm-   ``     -MMM+     -NMMMMMMMy   hMMMMMMMMN
            ``       mMMMMMMM-  :MMMMMM/  oMMMMM/ .hNNd:    -/:`      .odmmdy/`   :NMMMMMMN+
         -sdmmmh/    dMMMMMMN.   -shhs:   `/yhy/  /MMMMs `--`           ````       .ohddhs-
        :NMMMMMMMy   `odmNmy-                      /ss+``dNNm.         .-.`           ``
        yMMMMMMMMM`    ``.`                             `hNNh.       /dNNNms`      `-:-`
        :NMMMMMMMs          .--.      /yddy:    .::-`    `..`       /MMMMMMMh    `smNNNms`
         .ohdmdy:         -hmNNmh:   +MMMMMM/  /mMMNd.   ``         :MMMMMMMy    oMMMMMMMs   `-::.
            ```  ``      `NMMMMMMN.  +MMMMMN:  yMMMMM- -hmmh-        /hmNNdo`    +MMMMMMM+  +mNMNNh-
              -sdmmdy:   `mMMMMMMN`   :yhhs-   `+hhy:  oMMMMo          ...`       /hmmmh/  :MMMMMMMm
             /NMMMMMMNo   .sdmmmy-                     `+yy/`     -+ss+.            `.`    .NMMMMMMh
             dMMMMMMMMN     `..`                                 /NMMMMm-      :shyo.       -sdmmh+`
     `       /NMMMMMMMo                 .-.                      oMMMMMM/     sMMMMMm.        ```
 `/ydddho-    -sdmmdy:                `hNNms                     `odmmd+      yMMMMMN-   -shhs:
-mMMMMMMMNo     ````           `--.   `mMMMm                 `-//- `..        `odddy:   :NMMMMN/
mMMMMMMMMMM:            .//.   yNMN/   .+o/.                `dMMMNo       ./o+-  ``     /MMMMMM+
mMMMMMMMMMM:            dMMd   ommd:     -+o/.              .NMMMMy      -mMMMN+         /hddh/
:mMMMMMMMNs             -oo-    .:.     +NMMMm-         .//- -shy+`      -NMMMMo    `/oo:`  `
 `+ydmmdo-            `ohy/    smmdo    oMMMMN:        /NMMN+       `:++- -oso:    `dMMMMh
     ``               /MMMm   `NMMMN`    :oso-         :mMMN/       oMMMM/         `mMMMMh
                       :o+-    -oyo-         -+oo:`     .::.   -oo: /mNNm-     -+o/``/ss/`
                      `:oo:      .:/-`      oMMMMMh`          `NMMM- `--`     :MMMMy
                      oMMMM/    :mMMMm-     mMMMMMM.           +hho`     .+s+`.dNNm+
                      :mNNd-    oMMMMM/     -hmNNd/                 -o+. hMMMo  .-`
                       `..``    `/yhy/        `.`  `:oss+.          mMMh -shs.
                        :ydds.       .://.        `hMMMMMN+         -+/.
                       .MMMMMm      +NMMMMy       /MMMMMMMm
                        yNNNN+      mMMMMMM-      `dMMMMMN+    ````
                         .--` ``    :dNNNmo         :oss+.   -ydNNmh/
                            /hmmh+`   .--`  ./++:`          /MMMMMMMMy
                           :MMMMMMs        yMMMMMm/         hMMMMMMMMM      `-::-`
                           -NMMMMM+       /MMMMMMMN         :NMMMMMMMo    -yNMMMMMh:
                            .oyys-   ``   `mMMMMMMs          .ohmmds-    -NMMMMMMMMM+
                                  `+dNNmy- `+yhhs:   `ohmmds-            sMMMMMMMMMMd
                                  hMMMMMMM-         -NMMMMMMMs           :MMMMMMMMMMo
                                  dMMMMMMM:         yMMMMMMMMM`           :dMMMMMMm+
                                  .hMMMMm+          :MMMMMMMMy              .:++/.
                                    `--.             -ymMMNh/

EOF


cat <<EOF
Welcome to IOTA ICT Installer!
1. By pressing 'y' you agree to install the ICT node on your system.
2. By pressing 'y' you aknowledge that this installer requires a CLEAN operating system
   and may otherwise !!!BREAK!!! existing software on your server (visit link below).
5. If you already have a configured server, re-running this script might overwrite previous configuration.

EOF

read -p "Do you wish to proceed? [y/N] " yn
if echo "$yn" | grep -v -iq "^y"; then
    echo Cancelled
    exit 1
fi

#################
### Functions ###
#################
function set_dist() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        echo "Unsupported OS."
        exit 1
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        echo "Old OS version. Minimum required is 7."
        exit 1
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

function init_centos(){
    echo "Updating system packages..."
    yum update -y

    echo "Install epel-release..."
    yum install epel-release -y

    echo "Update epel packages..."
    yum update -y

    echo "Install yum utils..."
    yum install -y yum-utils

    set +e
    set +o pipefail
    if $(needs-restarting -r 2>&1 | grep -q "Reboot is required"); then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi
    set -o pipefail
    set -e

    echo "Installing Ansible and git..."
    yum install ansible git expect-devel cracklib newt -y
}

function init_ubuntu(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    apt-get install software-properties-common -y
    apt-add-repository ppa:ansible/ansible -y
    add-apt-repository universe -y
    apt-get update -y
    apt-get install ansible git expect-dev tcl libcrack2 cracklib-runtime whiptail -y
}

function init_debian(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        [ -z "$SKIP_REBOOT" ] && { inform_reboot; exit 0; }
    fi

    echo "Installing Ansible and git..."
    local ANSIBLE_SOURCE="deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
    grep -q "$ANSIBLE_SOURCE" /etc/apt/sources.list || echo "$ANSIBLE_SOURCE" >> /etc/apt/sources.list
    apt-get install dirmngr --install-recommends -y
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
    apt-get update -y
    apt-get install ansible git expect-dev tcl libcrack2 cracklib-runtime whiptail -y
}

function inform_reboot() {
    cat <<EOF >/etc/motd
======================== ICT PLAYBOOK ========================

To proceed with the installation, please re-run:

bash <(curl -s https://raw.githubusercontent.com/nuriel77/ict-playbook/master/ictnode_install.sh)

(make sure to run it as user root)

EOF

cat <<EOF


======================== PLEASE REBOOT AND RE-RUN THIS SCRIPT =========================

Some system packages have been updated which require a reboot
and allow the node installer to proceed with the installation.

*** Please reboot this machine and re-run this script ***


>>> To reboot run: 'reboot', and when the server is back online:
bash <(curl -s https://raw.githubusercontent.com/nuriel77/ict-playbook/master/ictnode_install.sh)

!! Remember to run this command as user 'root' !!

EOF
}

# Get primary IP from ICanHazIP, if it does not validate, fallback to local hostname
function set_primary_ip()
{
    echo "Getting external IP address..."
    local ip=$(curl -s -f --max-time 10 --retry 2 -4 'https://icanhazip.com')
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Got IP $ip"
        PRIMARY_IP=$ip
    else
        PRIMARY_IP=$(hostname -I|tr ' ' '\n'|head -1)
        echo "Failed to get external IP... using local IP $PRIMARY_IP instead"
    fi
}

function display_requirements_url() {
    echo "Please check requirements ... (to be done...)"
}

function check_arch() {
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        echo "ERROR: $ARCH architecture not supported"
        display_requirements_url
        exit 1
    fi
}

function set_ssh_port() {
    SSH_PORT=$(whiptail --inputbox "Please verify this is your active SSH port:" 8 78 "$SSH_PORT" --title "Verify SSH Port" 3>&1 1>&2 2>&3)
    if [[ $? -ne 0 ]] || [[ "$SSH_PORT" == "" ]]; then
        set_ssh_port
    elif [[ "$SSH_PORT" =~ [^0-9] ]] || [[ $SSH_PORT -gt 65535 ]] || [[ $SSH_PORT -lt 1 ]]; then
        whiptail --title "Invalid Input" \
                 --msgbox "Invalid input provided. Only numbers are allowed (1-65535)." \
                  8 78
        set_ssh_port
    fi
}

function run_playbook(){
    # Get default SSH port
    set +o pipefail
    SSH_PORT=$(grep ^Port /etc/ssh/sshd_config | awk {'print $2'})
    set -o pipefail
    if [[ "$SSH_PORT" != "" ]] && [[ "$SSH_PORT" != "22" ]]; then
        set_ssh_port
    else
        SSH_PORT=22
    fi
    echo "SSH port to use: $SSH_PORT"

    # Ansible output log file
    LOGFILE=/var/log/ict-playbook-$(date +%Y%m%d%H%M).log

    # Override ssh_port
    [[ $SSH_PORT -ne 22 ]] && echo "ssh_port: ${SSH_PORT}" > group_vars/all/z-ssh-port.yml

    # Run the playbook
    echo "*** Running playbook command: ansible-playbook -i inventory -v site.yml" | tee -a "$LOGFILE"
    set +e
    unbuffer ansible-playbook -i inventory -v site.yml | tee -a "$LOGFILE"
    RC=$?
    if [ $RC -ne 0 ]; then
        echo "ERROR! The playbook exited with failure(s). A log has been save here '$LOGFILE'"
        exit $RC
    fi
    set -e

    # Check playbook needs reboot
    if [ -f "/var/run/playbook_reboot" ]; then
        cat <<EOF >/etc/motd
-------------------- ICT PLAYBOOK --------------------

It seems you have rebooted the node. You can proceed with
the installation by running the command:

/opt/ict-playbook/rerun.sh

(make sure you are user root!)

-------------------- ICT PLAYBOOK --------------------
EOF

        cat <<EOF
-------------------- NOTE --------------------

The installer detected that the playbook requires a reboot,
most probably to enable a functionality which requires the reboot.

You can reboot the server using the command 'reboot'.

Once the server is back online you can use the following command
to proceed with the installation (become user root first):

/opt/ict-playbook/rerun.sh

-------------------- NOTE --------------------

EOF

        rm -f "/var/run/playbook_reboot"
        exit
    fi

    # Calling set_primary_ip
    set_primary_ip

    OUTPUT=$(cat <<EOF
* A log of this installation has been saved to: $LOGFILE

https://${PRIMARY_IP}:<ict_port>

* Note that your IP might be different as this one has been auto-detected in best-effort.

Thank you for installing an IOTA ICT node with the ICT-playbook!

EOF
)

    HEIGHT=$(expr $(echo "$OUTPUT"|wc -l) + 10)
    whiptail --title "Installation Done" \
             --msgbox "$OUTPUT" \
             $HEIGHT 78
}

#####################
### End Functions ###
#####################

# Incase we call a re-run
if [[ -n "$1" ]] && [[ "$1" == "rerun" ]]; then
    run_playbook
    exit
fi

### Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [ "$VER" != "7" ]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_centos
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17|18) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_ubuntu
elif [[ "$OS" =~ ^Debian ]]; then
    if [[ ! "$VER" =~ ^9 ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_debian
else
    echo "$OS not supported"
    exit 1
fi

echo "Verifying Ansible version..."
ANSIBLE_VERSION=$(ansible --version|head -1|awk {'print $2'}|cut -d. -f1-2)
if (( $(awk 'BEGIN {print ("'2.6'" > "'$ANSIBLE_VERSION'")}') )); then
    echo "Error: Ansible minimum version 2.6 required."
    echo "Please remove Ansible: (yum remove ansible -y for CentOS, or apt-get remove -y ansible for Ubuntu)."
    echo
    echo "Then refer to the documentation on how to get latest Ansible installed:"
    echo "http://docs.ansible.com/ansible/latest/intro_installation.html#latest-release-via-yum"
    echo "Note that for CentOS you may need to install Ansible from Epel to get version 2.6 or higher."
    exit 1
fi

echo "Git cloning ict-playbook repository..."
cd /opt

# Backup any existing ict-playbook directory
if [ -d ict-playbook ]; then
    echo "Backing up older ict-playbook directory..."
    rm -rf ict-playbook.backup
    mv ict-playbook ict-playbook.backup
fi

# Clone the repository (optional branch)
git clone $GIT_OPTIONS https://github.com/nuriel77/ict-playbook.git
cd ict-playbook

# Let user choose installation add-ons
#set_selections

# Get the administrators username
#set_admin_username

# get password
#get_admin_password

echo -e "\nRunning playbook..."
run_playbook

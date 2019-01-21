#!/bin/bash
#======================================================================================================================
#
#          FILE: setup.sh
#
#   DESCRIPTION: Deploy Rainbond Cluster with Glusterfs
#
#          BUGS: https://github.com/goodrain/rainbond-glusterfs/issues
#
#     COPYRIGHT: (c) 2019 by the Goodrain Delivery Team.
#
#       LICENSE: Apache 2.0
#       CREATED: 08/03/2018 11:38:02 AM
#======================================================================================================================

[[ $DEBUG ]] && set -ex || set -e

get_distribution() {
	lsb_dist=""
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	echo "$lsb_dist"
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

copy_from_centos(){
    info "Update default to CentOS" "$1"
    cp -a ./hack/chinaos/centos-release /etc/os-release
    mkdir -p /etc/yum.repos.d/backup >/dev/null 2>&1
    mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup >/dev/null 2>&1
    cp -a ./hack/chinaos/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
}

copy_from_ubuntu(){
    info "Update default to Ubuntu" "$1"
    cp -a ./hack/chinaos/ubuntu-release /etc/os-release
    cp -a ./hack/chinaos/ubuntu-lsb-release /etc/lsb-release
    cp -a /etc/apt/sources.list /etc/apt/sources.list.old
    cp -a ./hack/chinaos/sources.list /etc/apt/sources.list
}

other_type_linux(){
    lsb_dist=$( get_distribution )
    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
    case "$lsb_dist" in
        neokylin)
            copy_from_centos $lsb_dist
        ;;
        kylin)
            copy_from_ubuntu $lsb_dist
        ;;    
    esac
}

online_init(){
    lsb_dist=$( get_distribution )
    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
    progress "Detect $lsb_dist required packages..."
    case "$lsb_dist" in
		ubuntu|debian)
            apt-get update
            apt-get install -y sshpass python-pip uuid-runtime pwgen expect
		;;
		centos)
            yum install -y epel-release 
            yum makecache fast 
            yum install -y sshpass python-pip uuidgen pwgen expect
            pip install -U setuptools -i https://pypi.tuna.tsinghua.edu.cn/simple
		;;
		*)
            exit 1
		;;
    esac
    export LC_ALL=C
    pip install ansible -i https://pypi.tuna.tsinghua.edu.cn/simple

}

install(){
    ansible-playbook -i inventory/hosts glusterfs.yml
}

case $1 in
    *)
        other_type_linux
        online_init
        install
    ;;
esac

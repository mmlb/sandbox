#!/usr/bin/env bash

set -euxo pipefail

install_docker() {
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	update_apt
	apt-get install -y docker-ce docker-ce-cli containerd.io
}

install_docker_compose() {
	apt-get install --no-install-recommends python3-pip
	pip install docker-compose
}

install_iptables_persistent() {
	apt-get install --no-install-recommends iptables-persistent
}

apt-get() (
	# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
	DEBIAN_FRONTEND=noninteractive command apt-get --yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold "$@"
)

update_apt() (
	apt-get update
	apt-get upgrade
)

restart_docker_service() (
	service docker restart
)

# get_second_interface_from_bond0 returns the second interface of the bond0 interface
get_second_interface_from_bond0() {
	# if the ip is in a file in interfaces.d then lets assume this is a re-run and we can just
	# return the basename of the file (which should be named same as the interface)
	basename $(grep -lr "${layer2_ip}" /etc/network/interfaces.d) && return

	# sometimes the interfaces aren't sorted as expected in the /slaves file
	#
	# seeing as how this function is named *second* I figured its best to be
	# precise (via head -n2) when choosing the iface instead of choosing the last
	# iface and hoping there are only 2
	tr ' ' '\n' </sys/class/net/bond0/bonding/slaves | sort | head -n2 | tail -n1
}

# setup_layer2_network removes the second interface from bond0 and uses it for the layer2 network
# https://metal.equinix.com/developers/docs/layer2-networking/hybrid-unbonded-mode/
setup_layer2_network() {
	ifenslave -d bond0 "${layer2_interface}"
<<<<<<< HEAD
	#ip addr add ${ip_addr}/24 dev "${layer2_interface}"
	ip addr add 192.168.56.4/24 dev "${layer2_interface}"
=======
	ip addr add ${layer2_ip}/24 dev "${layer2_interface}"
>>>>>>> d4aae97 (wip)
	ip link set dev "${layer2_interface}" up

	# persist the new network settings
	# I tried getting rid of ^ and then just doing systemctl restart networking but that
	# didn't always work and was hard to recover from without a reboot sometimes
	sed -i \
		-e '/^auto '"${layer2_interface}"'/,/^\s*$/ d' \
		-e 's|'"${layer2_interface}"'||' \
		-e 's|\s*$||' \
		-e '/^source/ d' \
		-e '$ s|$|\n\nsource /etc/network/interfaces.d/*|' \
		/etc/network/interfaces

	cat >"/etc/network/interfaces.d/${layer2_interface}" <<-EOF
		auto ${layer2_interface}
		iface ${layer2_interface} inet static
		    address ${layer2_ip}
	EOF
}

# make_host_gw_server makes the host a gateway server
make_host_gw_server() {
	local incoming_interface=$1
	local outgoing_interface=$2

	# flush drops all rules, including docker's but docker will add them when starting up
	netfilter-persistent flush
	systemctl restart docker

	iptables -t nat -A POSTROUTING -o "${outgoing_interface}" -j MASQUERADE
	iptables -A FORWARD -i "${outgoing_interface}" -o "${incoming_interface}" -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i "${incoming_interface}" -o "${outgoing_interface}" -j ACCEPT

	# persist the new firewall setup
	netfilter-persistent save
}

update_apt
install_docker
install_docker_compose
restart_docker_service
mkdir -p /root/sandbox/compose

local layer2_ip=192.168.50.4
local layer2_interface
layer2_interface=$(get_second_interface_from_bond0)
install_iptables_persistent
setup_layer2_network "${layer2_interface}"
make_host_gw_server "${layer2_interface}" "bond0"

touch /root/setup.sh-is-done

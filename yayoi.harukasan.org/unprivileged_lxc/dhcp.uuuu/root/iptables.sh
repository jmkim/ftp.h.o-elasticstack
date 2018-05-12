#!/bin/bash

#
# Set the iptables rules
#
iptables_set_rules()
{
    echo -n "Setting new iptables rules... "
    #
    # Packet forwarding (for gateway)
    #
#    iptables -t filter -A FORWARD -i br0 -o br0 -j ACCEPT
#    iptables -t filter -A FORWARD -i lxc-bridge-nat -o lxc-bridge-nat -j ACCEPT
#
#    iptables -t filter -A FORWARD -i br0 -o lxc-bridge-nat -j ACCEPT
#    iptables -t filter -A FORWARD -i lxc-bridge-nat -o br0 -j ACCEPT

    #
    # IP masquerading (for gateway)
    #
#    iptables -t nat -A POSTROUTING -o br0 -j MASQUERADE
#    iptables -t nat -A POSTROUTING -o lxc-bridge-nat -j MASQUERADE

    #
    # Port forwarding
    #
#    iptables -t nat -A PREROUTING -i br0 -p tcp --dport http -j LOG --log-prefix='[netfilter] [http] '
#    iptables -t nat -A PREROUTING -i br0 -p tcp --dport http -j DNAT --to 10.20.81.31:80

#    iptables -t nat -A PREROUTING -i br0 -p tcp --dport https -j LOG --log-prefix='[netfilter] [https] '
#    iptables -t nat -A PREROUTING -i br0 -p tcp --dport https -j DNAT --to 10.20.81.31:443

    #
    # Access for specific port (Out->In)
    #
#    # HTTP
#    iptables -t filter -A INPUT -p tcp --dport http -j ACCEPT
#
#    # HTTPS
#    iptables -t filter -A INPUT -p tcp --dport https -j ACCEPT
#
#    # FTP
#    iptables -t filter -A INPUT -p tcp --dport ftp -j ACCEPT
#
#    # FTP (passive)
#    iptables -t filter -A INPUT -p tcp --dport ftp-data -j ACCEPT
#    iptables -t filter -A INPUT -p tcp --sport 32768:60999 --dport 32768:60999 -j ACCEPT
#
#    # NTP
#    iptables -t filter -A INPUT -p udp --dport ntp -j ACCEPT
#
#    # bootpc
#    iptables -t filter -A INPUT -p udp --dport bootpc -j ACCEPT
#
#    # bootps
#    iptables -t filter -A INPUT -p udp --dport bootps -j ACCEPT

    #
    # Access for ICMP (ping)
    #
    # Incoming
    iptables -t filter -A INPUT -p icmp --icmp-type echo-request -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -t filter -A OUTPUT -p icmp --icmp-type echo-reply -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Outgoing
    iptables -t filter -A OUTPUT -p icmp --icmp-type echo-request -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -t filter -A INPUT -p icmp --icmp-type echo-reply -m state --state ESTABLISHED,RELATED -j ACCEPT

    echo "done."
}


#
# Flush all existing iptables rules
#
iptables_flush_all()
{
    echo -n "Flushing all existing iptables rules... "
    iptables -t filter -F

    # Access for keeping the remote connection
    iptables -t filter -A INPUT -p tcp --dport ssh -j ACCEPT    

    iptables -t nat -F
    iptables -t mangle -F
    iptables -t raw -F
    iptables -t security -F

    # Delete all of user-defined chains
    iptables -X
    echo "done."
}


#
# Fallback policies
#
iptables_set_default_policy()
{
    iptables -t filter -P INPUT DROP

    # Access for localhost
    iptables -t filter -A INPUT -i lo -j ACCEPT

    # Established and related connections
    iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    iptables -t filter -P FORWARD DROP
    iptables -t filter -P OUTPUT ACCEPT
}


#
# Apply the iptables rules
#
iptables_apply()
{
    echo -n "Installing new iptables rules... "
    iptables-save > /etc/iptables/rules.v4
    iptables-restore < /etc/iptables/rules.v4
    echo "done."
    iptables-apply
}


#
# List the iptables rules
#
iptables_show()
{
    if [[ -z "$1" ]]; then

        table_names[0]="filter"
        table_names[1]="nat"

        for tname in ${table_names[*]}
        do
            echo "List of the rules in table \"$tname\":"
            iptables -t $tname -L -v
            echo ""
        done

    else

        echo "[$1]"
        iptables -t "$1" -L -v

    fi
}

iptables_show_all()
{
    table_names[0]="filter"
    table_names[1]="nat"
    table_names[2]="mangle"
    table_names[3]="raw"
    table_names[4]="security"

    for tname in ${table_names[*]}
    do
        echo "List of the rules in table \"$tname\":"
        iptables -t $tname -L -v
        echo ""
    done
}


#
# Main
#
case "$1" in
    install)
        iptables_flush_all
        iptables_set_default_policy
        iptables_set_rules
        iptables_apply
        ;;

    remove)
        iptables_flush_all
        iptables_set_default_policy
        ;;

    show)
        iptables_show "$2"
        ;;

    show-all)
        iptables_show_all
        ;;

    *)
        echo "Usage: $0 {install|remove|show|show-all}"
        echo "       $0 show [table name]"
        exit 1
esac

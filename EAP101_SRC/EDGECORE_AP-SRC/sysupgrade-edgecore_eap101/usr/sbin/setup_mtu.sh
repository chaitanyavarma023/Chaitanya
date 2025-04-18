#!/bin/sh

cmd="$1"
mtu=1400

del_mtu()
{
    local ip=$1
    if [ -n "${ip}" ]; then
        local d_ipro="$(ip ro li | grep -w ${ip} | grep mtu)"
        if [ -n "${d_ipro}" ]; then
            ip ro del ${d_ipro}
        fi
    fi
}

add_mtu()
{
    local ip=$1
    if [ -n "${ip}" ]; then
        del_mtu "${ip}"
        if [ -n "${mtu}" -a "${mtu}" != "0" ]; then
            # TODO: support IPv6 ?
            local gw="$(ip ro get ${ip} | grep via | cut -d' ' -f 3)"
            if [ -n "${gw}" ]; then
                ip ro add ${ip} via ${gw} mtu ${mtu}
            else
                local dev="$(ip ro get ${ip} | grep dev | cut -d' ' -f 3)"
                [ -n "${dev}" ] && ip ro add ${ip} mtu ${mtu} dev ${dev}
            fi
        fi
    fi
}

case "${cmd}" in
    'add_mtu')
        shift
        add_mtu $*
        ;;
    'del_mtu')
        shift
        del_mtu $*
        ;;
esac


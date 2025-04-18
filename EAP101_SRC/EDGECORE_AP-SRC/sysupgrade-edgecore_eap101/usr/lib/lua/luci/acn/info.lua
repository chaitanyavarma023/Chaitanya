
local cmd = arg[1]

if cmd then

    local acn =  require("luci.acn.util")

    -- Return ifname/devname for the given logical name
    if cmd == 'dev_name' and arg[2] then
        
        local is_eth, eth_id = acn.is_eth(arg[2])

        if is_eth then
            print(product.eth(eth_id)['dev_name'])
            return
        end

        print("")
    end

    -- Return port_ctl field for the given logical name
    if cmd == 'port_ctl' and arg[2] then
        
        local is_eth, eth_id = acn.is_eth(arg[2])

        if is_eth then
            print(product.eth(eth_id)['port_ctl'])
            return
        end

        print("")
    end
end
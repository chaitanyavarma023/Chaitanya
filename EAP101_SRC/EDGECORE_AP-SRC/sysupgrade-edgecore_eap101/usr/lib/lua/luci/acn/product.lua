
module("product", package.seeall)

-- Radio capabilities
radio_caps = nil

-- acc hw all
--    product_name=EAP104
--    Model=EAP104-WW
-- model is product_name of "acc hw all"
-- acc_model is Model of "acc hw all"

model = nil  -- Like OAP1234
branded_model = nil  -- Like ECWO5320
product_name = nil  -- Like ACN Outdoor really super awesome quad-radio AP
firmware_family = nil  -- SunSpot or SkyFire (based on brand)

acc_model = nil

local brand = require("luci.acn.brand")

function system_info(name)

    -- XXX TODO: use shared utilities

    local luci_util = (luci and luci.util) or require("luci.util")

    local output = luci_util.exec('acc hw get ' .. name)

    if output then
        local value = luci_util.split(output, "=")

        if string.find(output, "=") == #output-2 then
            return ""
        end

        return value[2]
    end
end

acc_model = system_info("Model") and system_info("Model"):gsub("\r", ""):gsub("\n", "") or ""

function load_product_info()
    ----------------------------  Default product if model not set ----------------------------
    if model == nil or model == '' then
        model = 'EAP101'
    end
    ----------------------------  Brand-dependent attributes ----------------------------
    product_name = brand.product_name(model)
    branded_model = brand.product_model(model)
    firmware_family = brand.firmware_family(model)
    ----------------------------  All Model Defaults  ----------------------------
    rssi_offset = 0
    platform = 'rtl'
    eth_desc = 'rtl865x'
    pppoe_prefix = 'ppp'
    wifi_prefix = 'ath'
    dev_name_3g = "3g-wan"
    num_wifi_radios = 2
    num_eth_ports = 2
    is_supports_3g = false
    is_supports_mesh = false
    -----------------------------------------------------------------------------

    ---------   EAP101  -------------------
    if model:find('EAP101') then
        is_supports_mesh = true
        eth_desc = 'IPQ6018'
        dev_name_mesh = "mesh0"
        num_eth_ports = 3
        wifi_prefix = 'wlan'

        function eth(id)
            local eth = {}
            id = tonumber(id)
            eth['id'] = id

            if id == 0 then
                eth['type'] = "Gigabit"
                eth['max'] = 2500
                eth['port_id'] = '5'
                eth['port_ctl'] = '5'
                eth['dev_name'] = "eth0"
                eth['logical_name'] = "eth0"
            elseif id == 1 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '4'
                eth['port_ctl'] = '4'
                eth['dev_name'] = "eth1"
                eth['logical_name'] = "eth1"
            elseif id == 2 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '3'
                eth['port_ctl'] = '3'
                eth['dev_name'] = "eth2"
                eth['logical_name'] = "eth2"
            else
                eth = nil
            end
            return eth
        end

        function load_radio_caps()
            radio_caps = {}

            radio_caps[0] = {}
            radio_caps[0]['max_ssids'] = 16
            radio_caps[0]['freq'] = '5'
            radio_caps[0]['supported_freq'] = { '5' }
            radio_caps[0]['has_ptp_mode'] = false
            radio_caps[0]['max_tx_streams'] = 2
            radio_caps[0]['max_rx_streams'] = 2
            radio_caps[0]['device'] = 'radio0'
            radio_caps[0]['wifi_iface'] = 'wlan0'
            radio_caps[0]['vendor'] = 'qca'

            radio_caps[1] = {}
            radio_caps[1]['max_ssids'] = 16
            radio_caps[1]['freq'] = '2.4'
            radio_caps[1]['supported_freq'] = { '2.4' }
            radio_caps[1]['has_ptp_mode'] = false
            radio_caps[1]['max_tx_streams'] = 2
            radio_caps[1]['max_rx_streams'] = 2
            radio_caps[1]['device'] = 'radio1'
            radio_caps[1]['wifi_iface'] = 'wlan1'
            radio_caps[1]['vendor'] = 'qca'
        end

    ---------   EAP102 / OAP103-BR  -------------------
    elseif model:find('EAP102') or model:find('OAP103%-BR') then
        is_supports_mesh = true
        eth_desc = 'IPQ8074'
        dev_name_mesh = "mesh0"
        wifi_prefix = 'wlan'

        function eth(id)
            local eth = {}
            id = tonumber(id)
            eth['id'] = id

            if id == 0 then
                eth['type'] = "Gigabit"
                eth['max'] = 2500
                eth['port_id'] = '5'
                eth['port_ctl'] = '5'
                eth['dev_name'] = "eth0"
                eth['logical_name'] = "eth0"
            elseif id == 1 then
                eth['type'] = "Gigabit"
                eth['max'] = 2500
                eth['port_id'] = '4'
                eth['port_ctl'] = '4'
                eth['dev_name'] = "eth1"
                eth['logical_name'] = "eth1"
            else
                eth = nil
            end
            return eth
        end

        function load_radio_caps()
            radio_caps = {}

            radio_caps[0] = {}
            radio_caps[0]['max_ssids'] = 16
            radio_caps[0]['freq'] = '5'
            radio_caps[0]['supported_freq'] = { '5' }
            radio_caps[0]['has_ptp_mode'] = false
            radio_caps[0]['max_tx_streams'] = 4
            radio_caps[0]['max_rx_streams'] = 4
            radio_caps[0]['device'] = 'radio0'
            radio_caps[0]['wifi_iface'] = 'wlan0'
            radio_caps[0]['vendor'] = 'qca'

            radio_caps[1] = {}
            radio_caps[1]['max_ssids'] = 16
            radio_caps[1]['freq'] = '2.4'
            radio_caps[1]['supported_freq'] = { '2.4' }
            radio_caps[1]['has_ptp_mode'] = false
            radio_caps[1]['max_tx_streams'] = 2
            radio_caps[1]['max_rx_streams'] = 2
            radio_caps[1]['device'] = 'radio1'
            radio_caps[1]['wifi_iface'] = 'wlan1'
            radio_caps[1]['vendor'] = 'qca'
        end

    ---------   EAP104   -------------------
    elseif model:find('EAP104') then
        is_supports_mesh = true
        eth_desc = 'IPQ5018'
        dev_name_mesh = "mesh0"
        num_eth_ports = 5
        wifi_prefix = 'wlan'

        function eth(id)
            local eth = {}
            id = tonumber(id)
            eth['id'] = id

            if id == 0 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '1'
                eth['port_ctl'] = '1'
                eth['dev_name'] = "eth0"
                eth['logical_name'] = "eth0"
            elseif id == 1 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '1'
                eth['port_ctl'] = '1'
                eth['dev_name'] = "lan1"
                eth['logical_name'] = "lan1"
            elseif id == 2 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '2'
                eth['port_ctl'] = '2'
                eth['dev_name'] = "lan2"
                eth['logical_name'] = "lan2"
            elseif id == 3 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '3'
                eth['port_ctl'] = '3'
                eth['dev_name'] = "lan3"
                eth['logical_name'] = "lan3"
            elseif id == 4 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '4'
                eth['port_ctl'] = '4'
                eth['dev_name'] = "lan4"
                eth['logical_name'] = "lan4"
                if not is_EAP104_lowcost() then
                  eth['poe_out'] = true
                end
            else
                eth = nil
            end
            return eth
        end

        function load_radio_caps()
            radio_caps = {}

            radio_caps[0] = {}
            radio_caps[0]['max_ssids'] = 16
            radio_caps[0]['freq'] = '5'
            radio_caps[0]['supported_freq'] = { '5' }
            radio_caps[0]['has_ptp_mode'] = false
            radio_caps[0]['max_tx_streams'] = 4
            radio_caps[0]['max_rx_streams'] = 4
            radio_caps[0]['device'] = 'radio0'
            radio_caps[0]['wifi_iface'] = 'wlan0'
            radio_caps[0]['vendor'] = 'qca'

            radio_caps[1] = {}
            radio_caps[1]['max_ssids'] = 16
            radio_caps[1]['freq'] = '2.4'
            radio_caps[1]['supported_freq'] = { '2.4' }
            radio_caps[1]['has_ptp_mode'] = false
            radio_caps[1]['max_tx_streams'] = 2
            radio_caps[1]['max_rx_streams'] = 2
            radio_caps[1]['device'] = 'radio1'
            radio_caps[1]['wifi_iface'] = 'wlan1'
            radio_caps[1]['vendor'] = 'qca'
        end

    ---------   SS-W2-AC2600 = SunSpot Wave 2 AC2600 -------------------
    elseif model:find('SS%-W2%-AC2600') then
        is_supports_3g = true
        eth_desc = 'IPQ806x'

        function eth(id)
            local eth = {}
            id = tonumber(id)
            eth['id'] = id

            if id == 0 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '0'
                eth['port_ctl'] = '0'
                eth['dev_name'] = 'eth0'
                eth['logical_name'] = 'eth0'
            elseif id == 1 then
                eth['type'] = "Gigabit"
                eth['max'] = 1000
                eth['port_id'] = '0'
                eth['port_ctl'] = '0'
                eth['dev_name'] = 'eth1'
                eth['logical_name'] = 'eth1'
            else
                eth = nil
            end

            return eth
        end

        function load_radio_caps()
            radio_caps = {}

            radio_caps[0] = {}
            radio_caps[0]['max_ssids'] = 8
            radio_caps[0]['freq'] = "5"
            radio_caps[0]['supported_freq'] = { "5" }
            radio_caps[0]['has_ptp_mode'] = false
            radio_caps[0]['max_tx_streams'] = 4
            radio_caps[0]['max_rx_streams'] = 4
            radio_caps[0]['device'] = 'wifi0'
            radio_caps[0]['vendor'] = 'qca'

            radio_caps[1] = {}
            radio_caps[1]['max_ssids'] = 8
            radio_caps[1]['freq'] = '2.4'
            radio_caps[1]['supported_freq'] = { '2.4' }
            radio_caps[1]['has_ptp_mode'] = false
            radio_caps[1]['max_tx_streams'] = 4
            radio_caps[1]['max_rx_streams'] = 4
            radio_caps[1]['device'] = 'wifi1'
            radio_caps[1]['vendor'] = 'qca'
        end
    end
end -- End load_product_info()

function radio(id)
    if radio_caps == nil then load_radio_caps() end
    return radio_caps[tonumber(id)]
end

function fcc_locked()
    return acc_model:find('%-FCC')
end

function thai_locked()
    return acc_model:find('%-TH')
end

function jp_locked()
    return acc_model:find('%-JP')
end

function in_locked()
    return acc_model:find('%-IN')
end

function br_locked()
    return acc_model:find('%-BR')
end

function is_sunspot()
    if product_name:match('SunSpot') then
        return true
    end
    return false
end

function is_OAP()
    if model:find('OAP') then
        return true
    end
    return false
end

function is_EAP101()
    if model:find('EAP101') then
        return true
    end
    return false
end

function is_EAP102()
    if model:find('EAP102') then
        return true
    end
    return false
end

function is_OAP103()
    if model:find('OAP103%-BR') then
        return true
    end
    return false
end

function is_EAP104()
    if model:find('EAP104') then
        return true
    end
    return false
end

function is_EAP104_lowcost()
    if is_EAP104() then
      -- for example: EAP104-WW-L
      local country, lowcost = acc_model:match("EAP104%-" .. "(%a+)%-(%a+)")
      if lowcost == "L" then
        return true
      end
    end
    return false
end

function company_name()
  local _company_name = brand.company_name or ""
  return _company_name
end

function supports_l2tp()
    return model:find('GW%-AC1200')
end

--Sunspot, Spark and Gateway support 3g/LTE
function supports_3g()
    return is_supports_3g
end

function supports_mesh()
    return is_supports_mesh
end

function support_QUECTEL_dongle()
    if model:find('SS%-W2%-AC2600') or model:find('SP%-W2%-AC1200') then
        return true
    end
    return false
end

-- Putting this here now so mgmtd can use it too
-- ONLY use this for display/reporting purposes!  It basically tells us what "real" tx power is for
-- both streams based on UCI/wifi driver reported value
-- NOTE: if you change this function, change in javascript too!!
function txpower_display_offset(num_streams)
    -- The 0.5 is our hack to round instead of floor to nearest int
    return math.floor(10*math.log10(num_streams) + 0.5)
end

if model == nil or model == '' then
    -- There is something, maybe carriage return, at end of string
    -- model = system_info("product_name"):gsub("\r", ""):gsub("\n", "")
    -- workaround until an mtdblock with SN is available for acc.c --
    model = system_info("product_name") and system_info("product_name"):gsub("\r", ""):gsub("\n", "")
    load_product_info()
end

function list_radios()
    local radios = {}
    for i = 0, num_wifi_radios - 1 do
        local rdata = radio(i)
        radios[#radios + 1] = rdata.device
    end
    return radios
end

function list_ports()
    local util =  require("luci.acn.util")
    local ports = {}
    local pdata = util.read_json("/etc/product.json")
    if pdata then
        for pname, _ in pairs(pdata.ports) do
            ports[#ports + 1] = pname
        end
        table.sort(ports)
    else
        for i = 0, num_eth_ports -1 do
            local port = eth(i)
            ports[#ports + 1] = port.dev_name
        end
    end
    return ports
end

return _M;

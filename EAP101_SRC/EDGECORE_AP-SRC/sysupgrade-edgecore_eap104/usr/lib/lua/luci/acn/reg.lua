local json = require "cjson.safe"
local util = require "luci.util"
local fs = require "nixio.fs"
local product = require("luci.acn.product")
local product_name = product.product_name:gsub("-[^%s]+", "")

module("reg", package.seeall)

function get_channel_info(curr_band, country)
    local cache_dir = "/tmp/regcache"
    local cache = cache_dir .. "/" .. country .. "_" .. curr_band .. ".json"

    cache_output = fs.readfile(cache)
    if cache_output then
        return json.decode(cache_output)
    end

    local data = {}
    data = get_qca_chans(curr_band, country)

    if data and #data > 0 then
        fs.mkdir(cache_dir)
        fs.writefile(cache, json.encode(data))
    end

    return data
end

function get_qca_chans(curr_band, country)
    local _cmd = "/sbin/dump_reg_chan.sh " .. curr_band .. " " .. country
    local output = util.exec(_cmd)
    local data = {}

    if output then
        data = json.decode(output) or {}
    end

    return data
end

function channelListDetails(curr_band, country)
    local ch_power = 0
    local data = get_channel_info(curr_band, country)

    local ret = {}
    if data then
        -- show all channel information
        for _, ch_info in ipairs(data) do
            local mode = ch_info.mode
            if ret[mode] == nil then
                ret[mode] = { auto = { chan = "auto", max_tx = 0 } }
            end

            ch_power = ch_info.max

            if ch_power and ch_power > ret[mode].auto.max_tx then
                  ret[mode].auto.max_tx = ch_power
            end
            local item = {
                  max_tx = ch_power,
                  chan_bw = mode,
                  freq = ch_info.freq,
                  dfs = ch_info.dfs,
                  chan = ch_info.chan
            }

            -- table keys are channel numbers to avoid duplicate channels
            ret[mode][tonumber(ch_info.chan)] = item
        end
    end
    return shift_mode_arrays(ret)

end

function shift_mode_arrays(db)
    -- make channel table numbering start from 1 so it can be correctly converted to json
    local ret = {}
    for mode, arr in pairs(db) do
        ret[mode] = {}
        ret[mode][1] = db[mode].auto
        for chan, data in pairs(arr) do
            if chan ~= "auto" then
                ret[mode][#ret[mode]+1] = data
            end
        end
    end
    return ret
end

function country_list(ifname)
    local iwinfo = luci.sys.wifi.getiwinfo(ifname)
    local country_json = iwinfo and iwinfo.countrylist
    local data = country_json and json.encode(country_json) or {}
    return data;
end

function get_TxPowerCert_info(country)
    local cert = "FCC"
    if product_name == "EAP104" then
        if country == "JP" then
            cert = "JP"
        elseif country == "KR" then
            cert = "KR"
        elseif country == "TH" then
            cert = "TH"
        elseif country == "IN" then
            cert = "IN"
        elseif country == "AT" or country == "BE" or country == "BG" or country == "HR" or country == "CZ"
            or country == "CY" or country == "DK" or country == "EE" or country == "FI" or country == "FR"
            or country == "DE" or country == "GR" or country == "HU" or country == "IS" or country == "IE"
            or country == "IT" or country == "LV" or country == "LT" or country == "LI" or country == "LU"
            or country == "MT" or country == "NO" or country == "NL" or country == "PL" or country == "PT"
            or country == "RO" or country == "SK" or country == "SI" or country == "ES" or country == "SE"
            or country == "CH" or country == "TR" or country == "GB" then
            cert = "ETSI"
        end
    else 
        if country == "US" then
            cert = "FCC"
        elseif country == "TW" then
            cert = "NCC"
        elseif country == "JP" then
            cert = "JP"
        elseif country == "KR" then
            cert = "KR"
        elseif country == "IN" then
            cert = "IN"
        elseif country == "PH" then
            cert = "PH"
        elseif country == "TH" then
            cert = "TH"
        elseif country == "CA" then
            cert = "IC"
        elseif country == "AU" or country == "NZ" then
            cert = "CTICK"
        elseif country == "BR" then
            cert = "BR"
        elseif country == "VN" then
            cert = "VN"
        elseif country == "ID" then
            cert = "ID"
        elseif country == "AT" or country == "BE" or country == "BG" or country == "HR" or country == "CZ"
            or country == "CY" or country == "DK" or country == "EE" or country == "FI" or country == "FR"
            or country == "DE" or country == "GR" or country == "HU" or country == "IS" or country == "IE"
            or country == "IT" or country == "LV" or country == "LT" or country == "LI" or country == "LU"
            or country == "MT" or country == "NO" or country == "NL" or country == "PL" or country == "PT"
            or country == "RO" or country == "SK" or country == "SI" or country == "ES" or country == "SE"
            or country == "CH" or country == "TR" or country == "GB" then
            cert = "ETSI"
        else
            cert = "ww"
        end
    end
    return cert;
end

-- custom txpower info
-- custom channel auto list info
function get_custom_info(curr_radio, country, radio_attr)
    -- curr_radio:5 for 5g, 2.4 for 2.4g
    local output = fs.readfile("/etc/fake_iw_reg/" .. product_name .. "/tx_power_list.json")
    local cert = get_TxPowerCert_info(country)
    local ret = {}

    if output then
        local data=json.decode(output)
        local tx_info=data[cert]
        ret = tx_info[tostring(curr_radio)][radio_attr]
    end

    return ret
end

return _M;

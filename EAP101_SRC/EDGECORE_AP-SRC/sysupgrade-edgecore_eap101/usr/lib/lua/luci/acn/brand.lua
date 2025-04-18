local acn_brand = {}
  
acn_brand.company_name      = "Edge-core Networks"

-- Defaults
acn_brand.register_url      = "https://regsvc.ignitenet.com/register"
acn_brand.controller_url    = "https://cloud.ignitenet.com/"

acn_brand.check_remote_fw   = false
acn_brand.mailaddress       = "ecwifi@edge-core.com"

function acn_brand.product_model(accton_model)

    if accton_model:find('OAP1232RL') then return accton_model:gsub('OAP1232RL', 'SF-AC1200') end
    if accton_model:find('OAP1235RL') then return accton_model:gsub('OAP1235RL', 'SF-AC866') end
    if accton_model:find('OAP7235RL') then return accton_model:gsub('OAP7235RL', 'SF-N300') end

    if accton_model:find('EAP1282') then return accton_model:gsub('EAP1282', 'SS-AC1200')  end

    if accton_model:find('ECW5211%-L') then return accton_model:gsub('A738', 'ECW5211-L') end
    if accton_model:find('EAP101') then return accton_model:gsub('EAP101', 'EAP101') end
    if accton_model:find('EAP102') then return accton_model:gsub('EAP102', 'EAP102') end
    if accton_model:find('EAP104') then return accton_model:gsub('EAP104', 'EAP104') end
    if accton_model:find('OAP103') then return accton_model:gsub('OAP103', 'OAP103') end
    --NOTE: SS-N300 is same for internal and ignitenet brand
    return accton_model
end

function acn_brand.product_name(accton_model)

    if accton_model:find('OAP1232RL') then return 'SkyFire AC1200' end
    if accton_model:find('OAP1235RL') then return 'SkyFire AC866' end
    if accton_model:find('OAP7235RL') then return 'SkyFire N300' end

    if accton_model:find('EAP1282') then return 'SunSpot AC1200' end
    if accton_model:find('SS%-N300') then return 'SunSpot N300' end
    if accton_model:find('SS%-W2%-AC2600') then return 'SunSpot Wave 2 AC2600' end
    if accton_model:find('WR1002RL') then return 'WR1002RL-1' end

    if accton_model:find('FN%-AC866') then return 'Fusion 5' end
    if accton_model:find('FN%-PTP%-AC866') then return 'Fusion 5 PtP' end

    if accton_model:find('SP%-N300') then return 'Spark N300' end
    if accton_model:find('SP%-AC750') then return 'Spark AC750' end
    if accton_model:find('SP%-W2%-AC1200') then return 'Spark WAVE 2 AC1200' end

    if accton_model:find('ML%-60%-35') or accton_model:find('ML%-60%-35%-1') then return 'MetroLinq PTP60-35' end
    if accton_model:find('ML%-60%-19') then return 'MetroLinq PTP60-19' end

    if accton_model:find('SS%-AC1900') then return 'SunSpot AC1900' end
    if accton_model:find('GW%-AC1200') then return 'Gateway AC1200' end

    if accton_model:find('ECW5211%-L') then return 'ECW5211-L' end
    if accton_model:find('EAP101') then return 'EAP101' end
    if accton_model:find('EAP102') then return 'EAP102' end
    if accton_model:find('EAP104') then return 'EAP104' end
    if accton_model:find('OAP103%-BR') then return 'OAP103-BR' end
    if accton_model:find('OAP103') then return 'OAP103' end

    return 'N/A'
end

-- This is the name that needs to show up somewhere in the firmware image file name
-- (if it doesn't we'll show a warning to user telling them they might have the wrong fw)
function acn_brand.firmware_family(accton_model)

    if accton_model:find('OAP') then return "SkyFire" end
    if accton_model:find('SS%-AC1900') then return "AC1900" end
    if accton_model:find('EAP') or accton_model:find('SS%-') then return "SunSpot" end
    if accton_model:find('FN') then return "Fusion" end
    if accton_model:find('ML') then return "MetroLinq" end
    if accton_model:find('SP%-W2') then return "Spark Wave 2" end
    if accton_model:find('SP') then return "Spark" end
    if accton_model:find('VDSL2') then return "VDSL2" end
    if accton_model:find('GW%-AC1200') then return "GW-AC1200" end
    if accton_model:find('ECW5211%-L') then return "ECW5211-L" end
    if accton_model:find('EAP101') then return "EAP101" end
    if accton_model:find('EAP102') then return "EAP102" end
    if accton_model:find('EAP104') then return "EAP104" end
    if accton_model:find('OAP103%-BR') then return "OAP103-BR" end
    if accton_model:find('OAP103') then return "OAP103" end

    return 'unknown'

end

return acn_brand

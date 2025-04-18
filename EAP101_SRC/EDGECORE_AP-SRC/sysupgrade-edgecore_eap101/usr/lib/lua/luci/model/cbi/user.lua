local acn_status = require "luci.acn.status"
local max_count = 10

m = Map("users", translate("User Accounts"))

-- JS file for this page
luci.dispatcher.context.page_js = '<script src="' .. luci.config.main.mediaurlbase .. '/js/users.js?ver=' .. acn_status.version() .. '"></script>\n'
.. "<script type='text/javascript'> \n"
.. '    var MAX_COUNT = ' .. max_count .. ';\n'
.. '</script>\n'
.. '<style>\n'
.. '#btn_save  { margin-left: 1px; }\n'
.. '</style>'

local s = m:section(TypedSection, "login", "")

s.addremove     = true
s.anonymous     = true

-- Use javascript/dynamic add remove template
s.template          = "cbi/tblsection_js"
s.add_btn_small     = true
s.add_btn_location  = "top"

s.table_name = "table_users"
s.no_stripe  = true

s.add_onclick = "addUserRow();"
s.del_onclick = "removeUserRow(this.id);"
s.max_count = max_count

local enabled   = s:option(Flag, "enabled", translate("Enabled"))
user_name       = s:option(Value, "name",translate("Username"))
--user_name.datatype = "maxlength(32)"
password        = s:option(Value, "passwd",translate("Password"))
--password.datatype = "rangelength(6, 20)"

enabled.switch_type = "yes_no"
enabled.default = 1 

user_name.custom_attr = "readonly=readonly"

-- Not sure how changing type to password requires us to set datatype in order for validation to happen...
password.password = true   

-- Validation happens in users.js

--TODO: to avoid running s.parse twince. but it should have better solution.
local runned_s_parse = false 

s.parse = function(self, nvld)
    if not runned_s_parse then
        runned_s_parse = true

        -- Have to do this first
        TypedSection.parse(self, nvld)

        local add_prefix = "acn.new" 
        local del_prefix = "acn.del" 

        -- This gets a list of all form values that begin with the prefix

        local new_users = self.map:formvaluetable(add_prefix)

        -- want these sorted
        local keys = {}
        for k in pairs(new_users) do 
          keys[#keys+1] = k 
        end

        table.sort(keys, 
          function(a,b) 
            return new_users[a] < new_users[b]  
          end
        )

        -- Need to use map.uci here so that the settings are saved
        for i,k in ipairs(keys) do

            local v = new_users[k]
            -- value is our client-side generated section name (like 45f30e)

            if v then
                -- v = cfg used for the temporary row

                local username = self.map:formvalue('cbid.users.cfg' .. v .. '.name')
                local passwd = self.map:formvalue('cbid.users.cfg' .. v .. '.passwd')
                local enabled = self.map:formvalue('cbid.users.cfg' .. v .. '.enabled') or "0"

                if username and #username > 0 and passwd and #passwd > 0 then

                    -- Create our anon section

                    local section = self:create()

                    if section then
                        self.map.uci:set("users", section, "name", username)
                        self.map.uci:set("users", section, "passwd", passwd) 
                        self.map.uci:set("users", section, "enabled", enabled) 

                        -- If we don't do the save/load below, something messes up the internal counter
                        -- and uci sections start overwriting each other (see #497)
                        self.map.uci:save("users")
                        self.map.uci:load("users")
                    end
                end
            end
        end

        table = self.map:formvaluetable(del_prefix .. ".users")

        -- Need to use map.uci here so that the settings are saved correctly
        for k, v in pairs(table) do
            if v and (v == "1" or v == 1) then 
               self.map.uci:delete("users", k)
            end 
        end

        -- Make us have at least one user
        local count = 0

        self.map.uci:foreach("users", "login", function(s)  count = count + 1 end)

        if count == 0 then
            local section = self:create()
            self.map.uci:set("users", section, "name", "root");
            self.map.uci:set("users", section, "passwd", "admin123") 
            self.map.uci:set("users", section, "enabled", "1") 
        end
    end
end

return m

#!/usr/bin/lua
--[[
ByteCnt:  1    1         1          2     1      4
          ---- --------- ---------- ----- ------ -------
FieldName:Type EventCode DataLength Event Status EventId
--]]

--Type
Command = 0x01
Event = 0x04

--OpCode
GapScan_enable = 0xFE51

--EventCode
HCI_LE_ExtEvent = 0xff

--Status
SUCCESS = 0x00

--Event
GAP_HCI_ExtentionCommandStatus = 0x067F
GAP_AdvertiserScannerEvent = 0x0613

--EventId
GAP_EVT_ADV_REPORT = 0x00400000
GAP_EVT_SCAN_ENABLED = 0x00010000

local write = io.write
function print(...)
  local n = select("#",...)
  for i = 1,n do
    local v = tostring(select(i,...))
    write(v)
    if i~=n then write'\t' end
  end
--		write'\n'
end

function printf(str, ...)
  return print(str:format(...))
end

function lshift(x, by)
  return x * 2 ^ by
end

function GetInt8(Payload, position)
  local uint = GetUint8(Payload, position)
  local max = 0x100 ^ 1
  return (uint >= max / 2 and uint - max) or uint
end

function GetUint8(Payload, position)
  return string.byte(Payload, position)
end

function GetUint32(Payload, position)
  return (lshift(string.byte(Payload, position+3),24) + lshift(string.byte(Payload, position+2),16) + lshift(string.byte(Payload, position+1),8) + string.byte(Payload, position))
end

function GetUint16(Payload, position)
  return (lshift(string.byte(Payload, position+1),8) + string.byte(Payload, position))
end

function hexdump(Payload,separator)
  for i=1,Payload:len(), 1 do
    io.write(string.format("%02X", Payload:byte(i)))
    if (i< Payload:len()) then
      io.write(separator)
    end
  end
end

ibeacon_hdr=string.char(0x1A,0xFF,0x4C,0x00,0x02,0x15)

function DumpAdvertiserData(Payload)
--[[
Len(1byte)+Type(1byte)+Data(Len bytes)
--]]
  print("DATA=")
  while( Payload:len() > 0 ) do
    local Len = GetUint8(Payload,1)
    local ADtype = GetUint8(Payload,2)

    hexdump(Payload:sub(1,Len+1),'')
    if (ADtype == 0xff) then -- manufacturer data
      if (Payload:sub(1,6) == ibeacon_hdr) then
        print(" MFR=ibeacon")
      end
    elseif (ADtype == 0x16) then
      local UUID = GetUint16(Payload,3)

      if (UUID == 0xFEAA) then --EddyStone
        local Type = GetUint8(Payload,5)

        if (Type==0x00) then
          print(" MFR=EddyStone-UID")
        elseif (Type==0x10) then
          print(" MFR=EddyStone-URL")
        elseif (Type==0x20) then
          print(" MFR=EddyStone-TLM")
        end
      end
    end
    Payload = string.sub(Payload,Len+2,-1)
  end
end

function DumpAdvertiserScannerEvent(Payload)
  local Status = GetUint8(Payload,3)
  local EventId = GetUint32(Payload,4)
  
  if (EventId==GAP_EVT_ADV_REPORT) and (Status==SUCCESS)
  then
    local MAC = string.sub(Payload,10,15)
    local RSSI = GetInt8(Payload,20)
    
    printf("MAC=%02X:%02X:%02X:%02X:%02X:%02X RSSI=%ddBm ", string.byte(MAC,6),string.byte(MAC,5),string.byte(MAC,4),
      string.byte(MAC,3),string.byte(MAC,2),string.byte(MAC,1), RSSI)

    DumpAdvertiserData(string.sub(Payload,32,-1))
    print("\n")
  end
end

function hci_event_paser()
  while true do
    local Header = io.read(3)
    if not Header then break end
    local EventType = GetUint8(Header,1)
    local EventCode = GetUint8(Header,2)
    local DataLength = GetUint8(Header,3)

    local Data = io.read(DataLength)
    local Event = GetUint16(Data,1)
--  print(EventType,EventCode,DataLength,Event)
    if not Data then break end
    if(Event==GAP_AdvertiserScannerEvent) then
      DumpAdvertiserScannerEvent(Data)
--    hexdump(ibeacon_hdr)
    end
  end
end

hci_event_paser()

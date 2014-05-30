--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--HOUSELOGIX RFID READER EXAMPLE
--Reads RFID tags from idTeck reader, pass card # to HouseLogix Access Control 
--Database for authentication.
--
-- Copyright (c) 2014 HouseLogix, Inc.
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////

CARD_LENGTH = 11
PACKET_HEADER = string.char(2)
PACKET_TAIL_LENGTH = 2
gReceiveBuffer = ""
gDebugFlag = false

--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--RECEIVEDFROMSERIAL
--Data might come 1 byte at a time on a HC300 or all at once on a HC800, let's just
--view it 1 byte at a time and call it a day
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////

function ReceivedFromSerial(idBinding, strData)
    if (strData) then dbg(string.format("(RECEIVED FROM SERIAL): %s",strData)) end
    dbg(hexdump(strData))
    for i=1,string.len(strData) do
        Buffer(strData:sub(i,i))
    end
end

function Buffer(data)
    if (NilException(data)) then return end
    if (data == PACKET_HEADER) then
        gReceiveBuffer = ""
    end
    gReceiveBuffer = gReceiveBuffer .. data
    if (string.len(gReceiveBuffer) == CARD_LENGTH) then
        ProcessBuffer(gReceiveBuffer)
    end
end

--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--PROCESSBUFFER
--Called when buffer meets CARD_LENGTH
--Pull the card number from packet and send it to database for authentication
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////

function ProcessBuffer(buffer)
    if (NilException(buffer)) then return end
    if (buffer:sub(1,1) == PACKET_HEADER and string.len(buffer) == CARD_LENGTH) then
        local cardNum = buffer:sub(2,CARD_LENGTH-PACKET_TAIL_LENGTH)
        dbg(string.format("CARD TO CHECK: %s",cardNum))
        C4:SendToProxy(2,"VERIFY",{CARD = cardNum})
    end
end

function ReceivedFromProxy(idBinding, strCommand, tParams)
    strCommand = strCommand or ""
    tParams = tParams or {}
    dbg(string.format("(RECEIVED FROM PROXY): %s",strCommand))
    if (COMMAND_HANDLER[strCommand] ~= nil and type(COMMAND_HANDLER[strCommand]) == "function") then
        COMMAND_HANDLER[strCommand](tParams)
    else
        dbg("(RECEIVED FROM PROXY): UNHANDLED COMMAND | THROW AWAY")
    end
end

--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--VERIFICATION_RESPONSE
--Returned from the database, we don't need to do anything with the response,
--since the database contains all the functionality
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////

COMMAND_HANDLER = {}

function COMMAND_HANDLER.VERIFICATION_RESPONSE(tParams)
    tParams = tParams or {}
    if (tParams["RESPONSE"]) then
        dbg("(VERIFICATION_RESPONSE): " .. tParams["RESPONSE"])
    else
        dbg("(VERIFICATION_RESPONSE): NIL RESPONSE")
    end
end

function OnPropertyChanged(strProperty)
    if (strProperty == "Debug Mode") then
        gDebugFlag = Properties[strProperty] == "ON"
    end
end

--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--HOUSELOGIX EXCEPTION HANDLING ROUTINES
--//////////--//////////--//////////--//////////--//////////--//////////--//////////
--//////////--//////////--//////////--//////////--//////////--//////////--//////////

function NilException(...)
    local throw = false
    local msg = ""
    if (gDebugFlag) then
        msg = string.format("(%s): ", string.upper(
            (function()
                return debug.getinfo(3,"n").name or debug.getinfo(3,"S").linedefined
            end)()
            ))
    end
    for i=1,select("#",...) do
        local temp = select(i,...)
        if (temp) then
            if (type(temp) == "string") then
                temp = string.format("\"%s\"",temp)
            end
            msg = msg .. temp .. " "
        else
            msg = msg .. "NIL PARAM"
            throw = true
        end
    end
    if (throw) then msg = msg .. " -- THROWING AWAY" end
    dbg(msg)
    return throw
end

function dbg(str)
    if (gDebugFlag) then print(str) end
end
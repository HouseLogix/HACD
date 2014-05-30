HouseLogix Access Control Database Integration API
============

The HouseLogix Access Control Database (HACD) is a device driver for Control4 that interfaces with supported RFID card readers and door locks, while providing a powerful administration panel for managing user access. To integrate a third party badge/card reader or door lock with HACD, this API provides simple hooks into the system.

See the example driver for full implementation.

Verify Card Number
============
Pass a card number to HACD for authentication checks.

```Lua
SendToProxy(binding, "VERIFY", { CARD = "123456789" })
```

Handle Response
============
After passing a card check to HACD, a pass/fail response will be returned.

```Lua
function ReceivedFromProxy(idBinding, strCommand, tParams)
	tParams = tParams or {}
    if (strCommand == "VERIFICATION_RESPONSE") then
    	if (tParams["RESPONSE"]) then
    		print("RESPONSE: " .. tParams["RESPONSE"])
    		--either "pass" or "fail"
    	end
    end  
end
```
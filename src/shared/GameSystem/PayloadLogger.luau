-- PayloadLogger.luau
-- Utility to print ResultPayloads cleanly to the console for debugging

local PayloadLogger = {}

function PayloadLogger.Log(payload)
    if not payload then return end
    
    print("\n========================================")
    print(string.format("[ResultPayload] %s", payload.Title or "RESULT"))
    print(string.format("Type: %s", payload.ResultType or "Neutral"))
    if payload.Description then
        print(string.format("Desc: %s", payload.Description))
    end
    
    if payload.StatChanges then
        print("--- Stats ---")
        for k, v in pairs(payload.StatChanges) do
            local sign = v >= 0 and "+" or ""
            print(string.format("  %s: %s%s", k, sign, tostring(v)))
        end
    end
    
    if payload.CommunityChanges then
        print("--- Communities ---")
        for k, v in pairs(payload.CommunityChanges) do
            local sign = v >= 0 and "+" or ""
            print(string.format("  %s: %s%s", k, sign, tostring(v)))
        end
    end
    
    if payload.SpecialEvents and #payload.SpecialEvents > 0 then
        print("--- Special Events ---")
        for _, event in ipairs(payload.SpecialEvents) do
            print(string.format("  * %s", event))
        end
    end
    print("========================================\n")
end

return PayloadLogger

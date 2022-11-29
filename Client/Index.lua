local traceLineSingle = Client.TraceLineSingle

--[[ Trace:Request ]]--
local function onTraceRequested(tStart, tEnd, iChannel, iTraceMode, tIgnoredActors, iTraceID)
    local tTrace = traceLineSingle(tStart, tEnd, iChannel, iTraceMode, tIgnoredActors)
    Events.CallRemote("Trace:Return", tTrace, iTraceID)
end

Events.SubscribeRemote("Trace:Request", onTraceRequested)
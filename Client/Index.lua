local table = table
local Trace = Trace
local Events = Events

local tTraceTypes = {
    [1] = Trace.BoxMulti,
    [2] = Trace.BoxSingle,
    [3] = Trace.CapsuleMulti,
    [4] = Trace.CapsuleSingle,
    [5] = Trace.LineMulti,
    [6] = Trace.LineSingle,
    [7] = Trace.SphereMulti,
    [8] = Trace.SphereSingle,
}

local function handleTrace(...)
    local tArgs = {...}

    local sID = tArgs[1]

    local iTraceType = tArgs[2]
    if not tTraceTypes[iTraceType] then return end

    local tRest = {}
    for i = 3, #tArgs do
        tRest[#tRest + 1] = tArgs[i]
    end

    local function doTrace()
        return tTraceTypes[iTraceType](table.unpack(tRest))
    end

    local bSuccess, xResultOrError = pcall(doTrace)
    if not bSuccess then
        Events.CallRemote("SVTr:Error", sID, xResultOrError:match(":%s(.+)$"))
        return
    end

    Events.CallRemote("SVTr:Pong", sID, xResultOrError)
end

Events.SubscribeRemote("SVTr", handleTrace)
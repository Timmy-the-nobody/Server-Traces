SVTrace = SVTrace or {}

local ipairs = ipairs
local type = type
local getmetatable = getmetatable
local mathRandom = math.random

local tAllPlayers = {}
local tPendingTraces = {}

-- Player: "Spawn"
Player.Subscribe("Spawn", function(pPlayer)
    tAllPlayers[#tAllPlayers + 1] = pPlayer
end)

-- Package: "Load"
Package.Subscribe("Load", function()
    tAllPlayers = Player.GetAll()
end)

-- Player: "Destroy"
Player.Subscribe("Destroy", function(pPlayer)
    local tNewPlayers = {}
    for _, v in ipairs(tAllPlayers) do
        if (v ~= pPlayer) then
            tNewPlayers[#tNewPlayers + 1] = pPlayer
        end
    end
    tAllPlayers = tNewPlayers

    -- Clears the traces queried to this player
    for k, v in pairs(tPendingTraces) do
        if (v.authority == pPlayer) then
            tPendingTraces[k] = nil
        end
    end
end)

-- Events: "SVTr:Pong"
Events.SubscribeRemote("SVTr:Pong", function(pPlayer, sID, tTrace)
    if not sID or not tPendingTraces[sID] then return end
    if (tPendingTraces[sID].authority ~= pPlayer) then return end

    tPendingTraces[sID].callback(tTrace)
    tPendingTraces[sID] = nil
end)

-- Events: "SVTr:Error"
Events.SubscribeRemote("SVTr:Error", function(pPlayer, sID, sError)
    if not sID or not tPendingTraces[sID] then return end
    if (tPendingTraces[sID].authority ~= pPlayer) then return end

    Console.Error(sError)
    tPendingTraces[sID] = nil
end)

---`🔹 Server`<br>
---Generates a random string, used for trace IDs
---@param iLen number @The length of the string
---@return string @The random string
---
local function generateRandomString(iLen)
    local sRand = ""
    for _ = 1, iLen do
        sRand = sRand..string.char(mathRandom(48, 122))
    end

    if tPendingTraces[sRand] then
        return generateRandomString(iLen)
    end

    return sRand
end

---`🔹 Server`<br>
---Handles the creation of a trace query
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---@return Player? @The authority player, or nil if failed
---@return string? @The trace unique ID, or nil if failed
---
local function handleTraceQuery(callback, pForceAutority)
    if (type(callback) ~= "function") then
        Console.Warn("SVTrace: Callback must be a function")
        return
    end

    if (#tAllPlayers == 0) then
        Console.Warn("SVTrace: No players found to perform a trace")
        return
    end

    local pAuthority
    if pForceAutority and (getmetatable(pForceAutority) == Player) then
        pAuthority = pForceAutority
    else
        pAuthority = tAllPlayers[mathRandom(1, #tAllPlayers)]
    end

    if not pAuthority then
        Console.Warn("SVTrace: No authority player found to perform a trace")
        return
    end

    local sID = generateRandomString(4)
    tPendingTraces[sID] = {authority = pAuthority, callback = callback}

    return pAuthority, sID
end

---`🔹 Server`<br>
---Trace a box against the world using object types and return overlapping hits and then first blocking hit<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.<br>
---Results are sorted, so a blocking hit (if found) will be the last element of the array<br>
---Only the single closest blocking result will be generated, no tests will be done after that
---@param tStart Vector @Start location of the box
---@param tEnd Vector @End location of the box
---@param tHalfSize Vector @Distance from the center of box along each axis
---@param tRot Rotator @Orientation of the box
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.BoxMulti(tStart, tEnd, tHalfSize, tRot, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 1, tStart, tEnd, tHalfSize, tRot, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a box against the world and returns a table with the first blocking hit information<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.
---@param tStart Vector @Start location of the box
---@param tEnd Vector @End location of the box
---@param tHalfSize Vector @Distance from the center of box along each axis
---@param tRot Rotator @Orientation of the box
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.BoxSingle(tStart, tEnd, tHalfSize, tRot, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 2, tStart, tEnd, tHalfSize, tRot, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a capsule against the world using object types and return overlapping hits and then first blocking hit<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.<br>
---Results are sorted, so a blocking hit (if found) will be the last element of the array<br>
---Only the single closest blocking result will be generated, no tests will be done after that
---@param tStart Vector @Start location of the capsule
---@param tEnd Vector @End location of the capsule
---@param fRad number @Radius of the capsule to sweep
---@param fHalfHeight number @Distance from center of capsule to tip of hemisphere endcap.
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.CapsuleMulti(tStart, tEnd, fRad, fHalfHeight, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 3, tStart, tEnd, fRad, fHalfHeight, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a capsule against the world and returns a table with the first blocking hit information<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.
---@param tStart Vector @Start location of the capsule
---@param tEnd Vector @End location of the capsule
---@param fRad number @Radius of the capsule to sweep
---@param fHalfHeight number @Distance from center of capsule to tip of hemisphere endcap.
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.CapsuleSingle(tStart, tEnd, fRad, fHalfHeight, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 4, tStart, tEnd, fRad, fHalfHeight, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a ray against the world using object types and return overlapping hits and then first blocking hit<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.<br>
---Results are sorted, so a blocking hit (if found) will be the last element of the array<br>
---Only the single closest blocking result will be generated, no tests will be done after that
---@param tStart Vector @Start location of the ray
---@param tEnd Vector @End location of the ray
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.LineMulti(tStart, tEnd, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 5, tStart, tEnd, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a ray against the world and returns a table with the first blocking hit information<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.
---@param tStart Vector @Start location of the ray
---@param tEnd Vector @End location of the ray
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.LineSingle(tStart, tEnd, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 6, tStart, tEnd, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a sphere against the world using object types and return overlapping hits and then first blocking hit<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.<br>
---Results are sorted, so a blocking hit (if found) will be the last element of the array<br>
---Only the single closest blocking result will be generated, no tests will be done after that
---@param tStart Vector @Start location of the sphere
---@param tEnd Vector @End location of the sphere
---@param fRad number @Radius of the sphere
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.SphereMulti(tStart, tEnd, fRad, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 7, tStart, tEnd, fRad, iCollisionChannel, iTraceMode, tIgnoredActors)
end

---`🔹 Server`<br>
---Trace a sphere against the world and returns a table with the first blocking hit information<br>
---Note: The Trace will collide with the ObjectType (in the Collision Settings), even if the channel is ignored below.
---@param tStart Vector @Start location of the sphere
---@param tEnd Vector @End location of the sphere
---@param fRad number @Radius of the sphere
---@param iCollisionChannel? number @Supports several channels separating by `|` (using bit-wise operations)
---@param iTraceMode? number @Trace Mode, pass all parameters separating by `|` (using bit-wise operations)
---@param tIgnoredActors? table @Array of actors to ignore during the trace
---@param callback function @The callback
---@param pForceAutority? Player @The player to force the call to be done on
---
function SVTrace.SphereSingle(tStart, tEnd, fRad, iCollisionChannel, iTraceMode, tIgnoredActors, callback, pForceAutority)
    local pAuthority, sID = handleTraceQuery(callback, pForceAutority)
    if not pAuthority then return end

    Events.CallRemote("SVTr", pAuthority, sID, 8, tStart, tEnd, fRad, iCollisionChannel, iTraceMode, tIgnoredActors)
end

-- Timer.SetTimeout(function()
--     SVTrace.LineSingle(Vector(0, 0, 100), Vector(0, 0, -100), CollisionChannel.WorldStatic, TraceMode["DrawDebug"], nil, function(tRes)
--         print(NanosTable.Dump(tRes))
--     end)
-- end, 5000)

Package.Export("SVTrace", SVTrace)
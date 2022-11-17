local ipairs = ipairs
local type = type
local getmetatable = getmetatable
local mathRandom = math.random
local isA = NanosUtils.IsA

local iLastTraceID = 0
local tReadyPlayers = {}
local tPendingTraces = {}

--[[ Player Ready ]]--
local function onPlayerReady( pPlayer )
    tReadyPlayers[ #tReadyPlayers + 1 ] = pPlayer
end

Player.Subscribe( "Ready", onPlayerReady )

--[[ Package Load ]]--
Package.Subscribe( "Load", function()
    for _, v in ipairs( Player.GetAll() ) do
        onPlayerReady( v )
    end
end )

--[[ Player Destroy ]]--
Player.Subscribe( "Destroy", function( pPlayer )
    local tNewPlayers = {}
    for _, v in ipairs( tReadyPlayers ) do
        if ( v ~= pPlayer ) then
            tNewPlayers[ #tNewPlayers + 1 ] = pPlayer
        end
    end
    tReadyPlayers = tNewPlayers
end )

--[[ onTraceReturn ]]--
local function onTraceReturn( pPlayer, tTrace, iTraceID )
    if not iTraceID or not tPendingTraces[ iTraceID ] then
        return
    end

    if ( tPendingTraces[ iTraceID ].authority ~= pPlayer ) then
        return
    end

    tPendingTraces[ iTraceID ].callback( tTrace )
    tPendingTraces[ iTraceID ] = nil
end

Events.Subscribe( "Trace:Return", onTraceReturn )

--[[ Trace ]]--
function Trace( callback, tStart, tEnd, iChannel, iTraceMode, tIgnoredActors, pForceAutority )
    if ( #tReadyPlayers == 0 ) then
        Package.Warn( "At least 1 ready client needed to perform a trace" )
        return
    end

    if not callback or ( type( callback ) ~= "function" ) then
        Package.Warn( "Callback parameter is invalid (function expected)" )
        return
    end

    if not tStart or ( getmetatable( tStart ) ~= Vector ) then
        Package.Warn( "Trace start parameter invalid (Vector expected)" )
        return
    end

    if not tEnd or ( getmetatable( tEnd ) ~= Vector ) then
        Package.Warn( "Trace end parameter invalid (Vector expected)" )
        return
    end

    iLastTraceID = ( iLastTraceID + 1 )

    local pAuthority
    if pForceAutority and isA( pForceAutority, Player ) then
        pAuthority = pForceAutority
    else
        pAuthority = tReadyPlayers[ mathRandom( 1, #tReadyPlayers ) ]
    end

    tPendingTraces[ iLastTraceID ] = {
        [ "authority" ] = pAuthority,
        [ "callback" ] = callback
    }

    Events.CallRemote( "Trace:Request", pAuthority,
        tStart,
        tEnd,
        ( iChannel or CollisionChannel.WorldStatic ),
        ( iTraceMode or 0 ),
        ( tIgnoredActors or {} ),
        iLastTraceID
    )
end

Package.Export( "Trace", Trace )
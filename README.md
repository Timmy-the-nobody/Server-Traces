# Installation
Drag and drop the **server-traces** folder in your server's **Packages** folder.
There's different ways to load the script, but the easiest would be to put **"server-traces"** in your server's **Config.toml** file, in the **packages[]** array.

# Desctiption
A new exported function (`Trace`) will be callable after installation. It looks like this:
```lua
Trace( fCallback, tStart, tEnd, iCollisionChannel, bComplex, bReturnEnt, bReturnPhysMat, tIgnoredAct )
```

The function takes the same parameters as `Client.Trace`, except for the first parameter which is the callback called once the result is received.
The callback has only one parameter which is the result of the trace, formatted the same way as clientside (table).

For the script to work there must be at least one player ready (who has loaded the map), the server trusts this client to retrieve the result of a trace.

# Exemple
```lua
Trace( function( tTrace )
    print( NanosUtils.Dump( tTrace ) )
end, Vector( 0, 0, 1000 ), Vector( 0, 0, -1000 ), nil, nil, nil, true )
```

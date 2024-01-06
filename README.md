# Desctiption
This will expose a new table (`SVTrace`) that works in a similar way than nanos world's `Trace` library

New functions:
- `SVTrace.BoxMulti`
- `SVTrace.BoxSingle`
- `SVTrace.CapsuleMulti`
- `SVTrace.CapsuleSingle`
- `SVTrace.LineMulti`
- `SVTrace.LineSingle`
- `SVTrace.SphereMulti`
- `SVTrace.SphereSingle`

The function takes the same parameters as clientside, except for 2 last parameter which are the callback and the forced authority.
The callback has only one parameter which is the result of the trace, formatted the same way as clientside (table).
The forced authority is the player who should handle the trace (this one is optionnal)

# Exemple

If you want to mimic a client trace that would be
```lua
Trace.LineSingle(Vector(0, 0, 100), Vector(0, 0, -100), CollisionChannel.WorldStatic, TraceMode.ReturnEntity, {})
```

You'd just have to call it the same way on the serverside (inside the `SVTrace` table instead of `Trace`), and with a callback to handle the result (and optionnaly the player who should have the authority on it), like:
```lua
SVTrace.LineSingle(Vector(0, 0, 100), Vector(0, 0, -100), CollisionChannel.WorldStatic, TraceMode.ReturnEntity, {}, function(tRes)
    print(NanosTable.Dump(tRes))
end, Player.GetByIndex(1))
```

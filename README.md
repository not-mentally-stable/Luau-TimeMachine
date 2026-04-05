a robust, type-strict state management container for Luau with built-in history tracking, undo/redo functionality, and granular observers.
Inspired by the TimeMachine utility for other languages.
Features
 * Undo/Redo: Effortlessly navigate through state history.
 * Transactions: Batch multiple changes into a single history entry.
 * Observers: watch specific keys or subscribe to every state change.
 * Luau Strict: Fully type-checked for a better developer experience.
# Quick Start
Basic Usage
```Luau
local TimeMachine = require("./TimeMachine.luau")

local machine = TimeMachine.new({
    score = 0,
    health = 100
})
```

Listen for specific changes
```Luau
machine:watch("score", function(new, old)
    print(`Score changed: {old} -> {new}`)
end)
```

set/get
```Luau
machine:set("score", 10) -- Output: Score changed: 0 -> 10
print(machine:get("score")) -- 10
```

Undo, Redo, and History
```Luau
machine:set("score", 20)
machine:set("score", 30)
```

other
```Luau
machine:undo() -- Back to 20
machine:undo() -- Back to 10
machine:redo() -- Forward to 20

print(machine:getIndex()) -- Current position in history
print(machine:getHistory()) -- Table of all previous states
```

Batching with Transactions
Use transactions to prevent the history stack from getting cluttered during multiple rapid updates.
```Luau
machine:beginTransaction()

machine:set("score", 50)
machine:set("health", 80)
machine:merge({ score = 100, health = 10 })

machine:endTransaction() -- All changes above count as ONE history step
```

# API Reference
| Method | Description |
|---|---|
| get(key) | Returns the value of a specific key. |
| set(key, value) | Updates a key and commits to history. |
| update(key, fn) | Updates a key using a transformation function. |
| merge(partial) | Merges a table of changes into the current state. |
| undo() | Reverts to the previous state. |
| redo() | Moves forward to the next state in history. |
| jump(index) | Jumps to a specific point in the history stack. |
| watch(key, cb) | Fires a callback when a specific key changes. |
| subscribe(cb) | Fires a callback on any state change. |
| beginTransaction() | Stops recording history steps until endTransaction is called. |

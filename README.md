# TimeMachine (Luau)
A lightweight, framework-agnostic state management module for Luau with built-in time-travel debugging, inspired by Time Travel Debugging (TTD) concepts from other languages.
Designed for drag-and-drop use in any Roblox experience or Luau projects, this module enables predictable state updates, history tracking, undo/redo, transactions, and reactive subscriptions.

# Installation
1. Download the ``TimeMachine.luau``
2. Place the module in anywhere accessible.
3. Require it:
```Luau
local TimeMachine = require("./TimeMachine")
```
or on **RobloxStudio** you can execute this command in the **commandbar**
```Luau
local Http = game:GetService("HttpService")
local Selection = game:GetService("Selection")
Http.HttpEnabled = true

local Module = Instance.new("ModuleScript", Selection:Get()[1] or game:GetService("ReplicatedStorage"))
Module.Name = "TimeMachine"
Module.Source = Http:GetAsync("https://raw.githubusercontent.com/not-mentally-stable/Luau-TimeMachine/refs/heads/main/TimeMachine.luau")
Selection:Set({Module})
```

# Quick Example
```Luau
local TimeMachine = require("./TimeMachine")

local store = TimeMachine.new({
    coins = 0,
    health = 100
})

store:subscribe(function(newState, oldState, diff)
    print("State changed!", diff)
end)

store:set("coins", 10)
store:update("health", function(h)
    return h - 20
end)

store:undo()
store:redo()
```

# API Documentation

``new(initial: State): TimeMachine``
Creates a new TimeMachine instance with an initial state.

``get(key: string): any``
Returns the value stored at the given key.

``set(key: string, value: any): ()``
Sets a value in the state and records it in history.

``update(key: string, fn: (any) -> any): ()``
Updates a value using a function that receives the current value.

``merge(partial: State): ()``
Merges a partial state into the current state.

``undo(): ()``
Reverts the state to the previous snapshot.

``redo(): ()``
Re-applies a previously undone state.

``jump(index: number): ()``
Jumps to a specific point in history.

``getHistory(): {State}``
Returns the full history of state snapshots.

``getIndex(): number``
Returns the current position in the history timeline.

``clearHistory(): ()``
Clears all history except the current state.

``commit(name: string, fn: (state: State) -> ()): ()``
Applies multiple changes in a single commit using a draft state.

``beginTransaction(): ()``
Starts a transaction. Changes won't be committed until ended.

``endTransaction(): ()``
Ends a transaction and commits all accumulated changes.

``watch(key: string, cb: (new: any, old: any) -> ()): ()``
Watches a specific key for changes.

``subscribe(cb: (newState: State, oldState: State, diff: Diff) -> ()): ()``
Subscribes to all state changes.

``getLastDiff(): Diff``
Returns the most recent state difference.

# Example Usage

```Luau
local TimeMachine = require("./TimeMachine")

local store = TimeMachine.new({
    score = 0,
    lives = 3
})

-- Watch a single key
store:watch("score", function(new, old)
    print("Score changed:", old, "->", new)
end)

-- Subscribe to all changes
store:subscribe(function(newState, oldState, diff)
    print("Global change:", diff)
end)

-- Basic updates
store:set("score", 100)

store:update("lives", function(lives)
    return lives - 1
end)

-- Batch updates with transaction
store:beginTransaction()
store:set("score", 200)
store:set("lives", 1)
store:endTransaction()

-- Undo / Redo
store:undo()
store:redo()

-- Jump in history
store:jump(1)

print("Current index:", store:getIndex())
```
---
[![License: ](https://img.shields.io/badge/License%3A-MIT-green?style=plastic)](https://github.com/not-mentally-stable/Luau-TimeMachine/blob/main/LICENSE)

[![Scripting Language: LUAU](https://img.shields.io/badge/Scripting%20Language%3A-LUAU-blue?style=plastic)](https://luau.org)

--!strict

export type State = {[string]: any}
export type Diff = {[string]: {old: any, new: any}}

type WatchCallback = (new: any, old: any) -> ()
type SubscribeCallback = (newState: State, oldState: State, diff: Diff) -> ()

export type TimeMachine = {
    get: (self: TimeMachine, key: string) -> any,
    set: (self: TimeMachine, key: string, value: any) -> (),
    update: (self: TimeMachine, key: string, fn: (any) -> any) -> (),
    merge: (self: TimeMachine, partial: State) -> (),
    undo: (self: TimeMachine) -> (),
    redo: (self: TimeMachine) -> (),
    jump: (self: TimeMachine, index: number) -> (),
    getHistory: (self: TimeMachine) -> {State},
    getIndex: (self: TimeMachine) -> number,
    clearHistory: (self: TimeMachine) -> (),
    commit: (self: TimeMachine, name: string, fn: (state: State) -> ()) -> (),
    beginTransaction: (self: TimeMachine) -> (),
    endTransaction: (self: TimeMachine) -> (),
    watch: (self: TimeMachine, key: string, cb: WatchCallback) -> (),
    subscribe: (self: TimeMachine, cb: SubscribeCallback) -> (),
    getLastDiff: (self: TimeMachine) -> Diff,
}

type Internal = TimeMachine & {
    _state: State,
    _history: {State},
    _index: number,
    _watchers: {[string]: {WatchCallback}},
    _subscribers: {SubscribeCallback},
    _lastDiff: Diff,
    _inTransaction: boolean,
    _transactionSnapshot: State?,
    _apply: (self: Internal, newState: State) -> (),
    _commitState: (self: Internal, newState: State) -> (),
}

local function shallowCopy(tbl: State): State
    local new = {}
    for k, v in tbl do
        new[k] = v
    end
    return new
end

local function computeDiff(old: State, new: State): Diff
    local diff: Diff = {}
    for k, v in new do
        if old[k] ~= v then
            diff[k] = {old = old[k], new = v}
        end
    end
    for k, v in old do
        if new[k] == nil then
            diff[k] = {old = v, new = nil}
        end
    end
    return diff
end

local TimeMachine = {}
TimeMachine.__index = TimeMachine

function TimeMachine.new(initial: State): TimeMachine
    local self = setmetatable({}, TimeMachine) :: any
    self._state = shallowCopy(initial)
    self._history = {shallowCopy(initial)}
    self._index = 1
    self._watchers = {}
    self._subscribers = {}
    self._lastDiff = {}
    self._inTransaction = false
    self._transactionSnapshot = nil
    return (self :: Internal)
end

function TimeMachine._apply(self: Internal, newState: State)
    local oldState = self._state
    self._state = newState
    local diff = computeDiff(oldState, newState)
    self._lastDiff = diff
    for key, change in diff do
        local watchers = self._watchers[key]
        if watchers then
            for _, cb in watchers do
                cb(change.new, change.old)
            end
        end
    end
    for _, cb in self._subscribers do
        cb(newState, oldState, diff)
    end
end

function TimeMachine.get(self: Internal, key: string): any
    return self._state[key]
end

function TimeMachine.set(self: Internal, key: string, value: any)
    local newState = shallowCopy(self._state)
    newState[key] = value
    if self._inTransaction then
        self._state = newState
        return
    end
    self:_commitState(newState)
end

function TimeMachine.update(self: Internal, key: string, fn: (any) -> any)
    self:set(key, fn(self._state[key]))
end

function TimeMachine.merge(self: Internal, partial: State)
    local newState = shallowCopy(self._state)
    for k, v in partial do
        newState[k] = v
    end
    if self._inTransaction then
        self._state = newState
        return
    end
    self:_commitState(newState)
end

function TimeMachine._commitState(self: Internal, newState: State)
    for i = #self._history, self._index + 1, -1 do
        table.remove(self._history, i)
    end
    table.insert(self._history, shallowCopy(newState))
    self._index += 1
    self:_apply(newState)
end

function TimeMachine.commit(self: Internal, name: string, fn: (state: State) -> ())
    local draft = shallowCopy(self._state)
    fn(draft)
    self:_commitState(draft)
end

function TimeMachine.undo(self: Internal)
    if self._index <= 1 then return end
    self._index -= 1
    self:_apply(shallowCopy(self._history[self._index]))
end

function TimeMachine.redo(self: Internal)
    if self._index >= #self._history then return end
    self._index += 1
    self:_apply(shallowCopy(self._history[self._index]))
end

function TimeMachine.jump(self: Internal, index: number)
    if index < 1 or index > #self._history then return end
    self._index = index
    self:_apply(shallowCopy(self._history[index]))
end

function TimeMachine.getHistory(self: Internal): {State}
    return self._history
end

function TimeMachine.getIndex(self: Internal): number
    return self._index
end

function TimeMachine.clearHistory(self: Internal)
    self._history = {shallowCopy(self._state)}
    self._index = 1
end

function TimeMachine.beginTransaction(self: Internal)
    if self._inTransaction then return end
    self._inTransaction = true
    self._transactionSnapshot = shallowCopy(self._state)
end

function TimeMachine.endTransaction(self: Internal)
    if not self._inTransaction then return end
    self._inTransaction = false
    local snapshot = self._transactionSnapshot
    self._transactionSnapshot = nil
    if snapshot then
        self:_commitState(self._state)
    end
end

function TimeMachine.watch(self: Internal, key: string, cb: WatchCallback)
    if not self._watchers[key] then
        self._watchers[key] = {}
    end
    table.insert(self._watchers[key], cb)
end

function TimeMachine.subscribe(self: Internal, cb: SubscribeCallback)
    table.insert(self._subscribers, cb)
end

function TimeMachine.getLastDiff(self: Internal): Diff
    return self._lastDiff
end

return {
    new = TimeMachine.new
} :: { new: (initial: State) -> TimeMachine }

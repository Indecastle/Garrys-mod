--@name Coroutine Wrapper
--@author Jacbo
--@shared
-- https://github.com/Jacbo1/Public-Starfall/tree/main/Coroutine%20Wrapper
-- INCLUDE AND REQUIRE SAFENET FIRST IF USING IT
-- It will automatically wrap everything in a coroutine that is run by
-- hook.add
-- timer.simple
-- timer.create
-- timer.adjust
-- net.receive
-- safeNet.receive (safeNet must be included and required before this library)
-- corWrapHook
-- corWrap

-- For anything not in the above cases, you must call corWrap(func, args ...) to wrap it.
-- This will resume the coroutine in a think hook.
-- Use corWrapHook(func, hookname, args ...) to specify a hook to resume in.


local oldNet = net
local net = safeNet or oldNet
local net_receive = oldNet.receive
local table_insert = table.insert
local coroutine_create = coroutine.create
local coroutine_status = coroutine.status
local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield
local hook_add = hook.add
local timer_simple = timer.simple
local timer_create = timer.create
local timer_adjust = timer.adjust

local hook_name = 0

function corWrapHook(func, hookname, ...)
    local cor = coroutine_create(func)
    coroutine_resume(cor, ...)
    if coroutine_status(cor) ~= "dead" then
        local name = "corwrap " .. hook_name
        hook_name = hook_name + 1
        hook_add(hookname, name, function()
            local status = coroutine_status(cor)
            if status == "dead" then
                hook.remove(hookname, name)
            else
                coroutine_resume(cor)
            end
        end)
    end
end

function corWrap(func, ...)
    corWrapHook(func, "think", ...)
end

oldNet.receive = function(name, func)
    net_receive(name, (func and function(size, ply)
        corWrap(func, size, ply)
    end or nil))
end

if safeNet then
    net.wrapReceive(corWrap)
end

hook.add = function(hookname, name, func)
    local cor = coroutine_create(func)
    hook_add(hookname, name, function(...)
        local status = coroutine_status(cor)
        if status == "dead" then
            cor = coroutine_create(func)
        end
        return coroutine_resume(cor, ...)
    end)
end

timer.simple = function(delay, func)
    timer_simple(delay, function()
        corWrap(func)
    end)
end

timer.create = function(name, delay, reps, func)
    timer_create(name, delay, reps, function()
        corWrap(func)
    end)
end

timer.adjust = function(name, delay, reps, func)
    timer_adjust(name, delay, reps, (func and function()
        corWrap(func)
    end or nil))
end

if CLIENT then
    local bass_loadURL = bass.loadURL
    bass.loadURL = function(path, flags, callback)
        return bass_loadURL(path, flags, function(...)
            corWrap(callback, ...)
        end)
    end
end

utils = {}
utils.debug = false
utils.framePoints = { -- shorthand 'FRAMEPOINT' for terser code.
    tl = FRAMEPOINT_TOPLEFT, t = FRAMEPOINT_TOP,
    tr = FRAMEPOINT_TOPRIGHT, r = FRAMEPOINT_RIGHT,
    br = FRAMEPOINT_BOTTOMRIGHT, b = FRAMEPOINT_BOTTOM,
    bl = FRAMEPOINT_BOTTOMLEFT, l = FRAMEPOINT_LEFT,
    c = FRAMEPOINT_CENTER,
}

function utils.debugfunc(func, name)
    local name = name or ""
    local result
    local passed, data = pcall(function()
        result = func()
        return "func " .. name .. " passed"
    end)
    if not passed then
        print(name, passed, data)
    end
    passed = nil
    data = nil
    return result
end

function utils.printPassed(since, name)
    if utils.debugTime then
        local call = utils.timedCalls[name] or 0
        call = call + 1
        utils.timedCalls[name] = call
        local duration = os.time() - since
        --if duration > 0 then
        print(name .. ": " .. tostring(call) .. ". call took " .. tostring(duration) .. "ms")
        --end
    end
end

function utils.debugfuncTimed(func, name)
    local start = os.time()
    local name = name or ""
    local result
    local passed, data = pcall(function()
        result = func()
        utils.printPassed(start, name)
        return "func " .. name .. " passed"
    end)
    if not passed then
        print(name, passed, data)
    end
    passed = nil
    data = nil
    utils.printPassed(start, name)
    return result
end

function utils.newclass(t)
    local t = t
    t.__index = t
    t.lookupt = {}
    t.new = function()
        local o = {}
        setmetatable(o, t)
        return o
    end
    t.destroy = function()
        t.lookupt[t] = nil
    end
    if utils.debug then
        print("made new class for " .. tostring(t))
    end
end

function utils.timed(dur, func)
    local tmr = CreateTimer()
    utils.debugfunc(function()
        TimerStart(tmr, dur, false, function()
            func()
            ReleaseTimer(tmr)
        end)
        return tmr
    end, 'utilsTimed')
    return tmr;
end

function utils.timedSkippable(dur, func)
    SkippableTimers:start(dur, func)
end

function utils.timedRepeat(dur, count, func)
    local tmr = CreateTimer()
    utils.debugfunc(function()
        local t, c = count, 0
        if t == nil then
            TimerStart(tmr, dur, true, function()
                func(tmr)
            end)
        else
            TimerStart(tmr, dur, true, function()
                func(tmr)
                c = c + 1
                if c >= t then
                    ReleaseTimer(timer)
                end
            end)
        end
        return tmr
    end, 'utilsTimedRepeat')
    return tmr;
end

function utils.tableCollapse(t)
    for index, value in pairs(t) do
        if value == nil then
            table.remove(t, index)
        end
    end
end

-- :: clones a table and any child tables (setting metatables)
-- @t = table to copy
function utils.deepCopy(t)
    local t2 = {}
    if getmetatable(t) then
        setmetatable(t2, getmetatable(t))
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            local newt = {}
            if getmetatable(v) then
                setmetatable(newt, getmetatable(v))
            end
            for k2, v2 in pairs(v) do
                newt[k2] = v2
            end
            t2[k] = newt
        else
            t2[k] = v
        end
    end
    return t2
end

function utils.destroyTable(t)
    for i, v in pairs(t) do
        if type(v) == "table" then
            for i2, v2 in pairs(v) do
                v2 = nil
                i2 = nil
            end
        else
            v = nil
            i = nil
        end
    end
end

-- @bool = true to fade out (hide); false to fade in (show).
function utils.fadeFrame(bool, fh, dur)
    BlzFrameSetVisible(fh, true)
    local bool = bool
    local fh = fh
    local alpha = 255
    local int = math.floor(255 / math.floor(dur / 0.03))
    -- show:
    if bool then
        BlzFrameSetVisible(fh, true)
        BlzFrameSetAlpha(fh, 255)
        utils.timedRepeat(0.03, nil, function(timer)
            if BlzFrameGetAlpha(fh) > 0 and BlzFrameGetAlpha(fh) > int then
                alpha = alpha - int
                BlzFrameSetAlpha(fh, alpha)
            else
                BlzFrameSetAlpha(fh, 0)
                BlzFrameSetVisible(fh, false)
                ReleaseTimer(timer)
            end
        end)
        -- hide:
    else
        BlzFrameSetVisible(fh, true)
        BlzFrameSetAlpha(fh, 0)
        utils.timedRepeat(0.03, nil, function(timer)
            if BlzFrameGetAlpha(fh) ~= 255 and BlzFrameGetAlpha(fh) < 255 - int then
                alpha = alpha + int
                BlzFrameSetAlpha(fh, alpha)
            else
                BlzFrameSetAlpha(fh, 255)
                BlzFrameSetVisible(fh, true)
                ReleaseTimer(timer)
            end
        end)
    end
end

function utils.playSound(snd, p)
    local p = p or GetTriggerPlayer()
    if p == GetLocalPlayer() then
        StopSound(snd, false, false)
        StartSound(snd)
    end
end

function utils.playSoundAll(snd)
    utils.looplocalp(function()
        StopSound(snd, false, false)
        StartSound(snd)
    end)
end

-- @func = run this for all players, but local only.
function utils.looplocalp(func)
    ForForce(bj_FORCE_ALL_PLAYERS, function()
        if GetEnumPlayer() == GetLocalPlayer() then
            func(GetEnumPlayer())
        end
    end)
end


function utils.tableLength(t)
    if not t then
        return nil
    end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function utils.ifElse(condition, onTrue, onFalse)
    if condition then
        return onTrue
    else
        return onFalse
    end
end

function ArrayRemove(t, fnRemove)
    local j, n = 1, #t
    for i=1,n do
        if (fnRemove(t, i)) then --fnRemove(table, key) -- remove value
            t[i] = nil
        else --keep value
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i]
                t[i] = nil
            end
            j = j + 1 -- Increment position of where we'll place the next kept value.
        end
    end
    return t
end

function utils:printFrameStructure(frame)
    print("STRUCTURE OF FRAME " .. BlzFrameGetName(frame) .. ": ")
    local childrenCount = BlzFrameGetChildrenCount(frame)
    print("  CHILDREN COUNT: " .. tostring(childrenCount))
    for i = 0, childrenCount do
        print("  CHILD " .. tostring(i) .. ": " .. BlzFrameGetName(BlzFrameGetChild(frame, i)))
    end
end

function utils:getChildByName(parent, expectedChildName)
    local childrenCount = BlzFrameGetChildrenCount(parent)
    for i = 0, childrenCount do
        local child = BlzFrameGetChild(parent, i)
        local childName = BlzFrameGetName(child)
        if childName == expectedChildName then
            return child
        end
    end
end

function utils.printDupa()
    print("dupa")
end

function ReleaseTimer(whichTimer)
    PauseTimer(whichTimer)
    DestroyTimer(whichTimer)
end

function utils.fadeOut(duration)
    CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, duration, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 1, 1, 1, 0)
end

function utils.fadeIn(duration)
    CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, duration, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 1, 1, 1, 0)
end

function printWarn(msg)
    print("[WARN] " .. msg)
end


local function valueToString(v, prefix)
    if type(v) == "table" then
        return utils.toString(v, prefix .. " ")
    else
        return tostring(v)
    end
end

function utils.toString(o, prefix)
    local s = "{\n"
    for key, value in pairs(o) do
        local valueString = valueToString(value, prefix)
        s = s .. prefix .. "\"" .. key .. "\": \"" .. valueString .. "\",\n"
    end
    s = s .. "\n}\n"
    return s
end

function utils.printToString(label, o)
    print(label .. ": " .. utils.toString(o, " "))
end

function AngleBetweenCoordinatesDegrees(x, y, x2, y2)
    return Atan2BJ(y2 - y, x2 - x)
end

function DistanceBetweenCoordinates(x1, y1, x2, y2)
    local dx = (x2 - x1)
    local dy = (y2 - y1)

    return SquareRoot(dx*dx + dy*dy)
end
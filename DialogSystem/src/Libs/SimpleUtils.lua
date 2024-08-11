SimpleUtils = {}
SimpleUtils.debug = false
SimpleUtils.debugTime = false

function SimpleUtils.debugFunc(func, name)
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

function SimpleUtils.printTime(since, name)
    if SimpleUtils.debugTime then
        local call = SimpleUtils.timedCalls[name] or 0
        call = call + 1
        SimpleUtils.timedCalls[name] = call
        local duration = os.time() - since
        --if duration > 0 then
        print(name .. ": " .. tostring(call) .. ". call took " .. tostring(duration) .. "ms")
        --end
    end
end

function SimpleUtils.debugFuncTimed(func, name)
    local start = os.time()
    local name = name or ""
    local result
    local passed, data = pcall(function()
        result = func()
        SimpleUtils.printTime(start, name)
        return "func " .. name .. " passed"
    end)
    if not passed then
        print(name, passed, data)
    end
    passed = nil
    data = nil
    SimpleUtils.printTime(start, name)
    return result
end

function SimpleUtils.newClass(t)
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
    if SimpleUtils.debug then
        print("made new class for " .. tostring(t))
    end
end

function SimpleUtils.timed(dur, func)
    local tmr = CreateTimer()
    SimpleUtils.debugFunc(function()
        TimerStart(tmr, dur, false, function()
            func()
            ReleaseTimer(tmr)
        end)
        return tmr
    end, 'SimpleUtilsTimed')
    return tmr;
end

function SimpleUtils.timedSkippable(dur, func)
    SkippableTimers:start(dur, func)
end

function SimpleUtils.timedRepeat(dur, count, func)
    local tmr = CreateTimer()
    SimpleUtils.debugFunc(function()
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
                    ReleaseTimer(tmr)
                end
            end)
        end
        return tmr
    end, 'SimpleUtilsTimedRepeat')
    return tmr;
end

-- :: clones a table and any child tables (setting metatables)
-- @t = table to copy
function SimpleUtils.deepCopy(t)
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

function SimpleUtils.destroyTable(t)
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

function SimpleUtils.playSound(snd)
    StopSound(snd, false, false)
    StartSound(snd)
end

function SimpleUtils.tableLength(t)
    if not t then
        return nil
    end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function SimpleUtils.ifElse(condition, onTrue, onFalse)
    if condition then
        return onTrue
    else
        return onFalse
    end
end

function SimpleUtils.printDupa()
    print("dupa")
end

function SimpleUtils.fadeOut(duration)
    CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, duration, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 1, 1, 1, 0)
end

function SimpleUtils.fadeIn(duration)
    CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, duration, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 1, 1, 1, 0)
end

local function valueToString(v, prefix)
    if type(v) == "table" then
        return SimpleUtils.toString(v, prefix .. " ")
    else
        return tostring(v)
    end
end

function SimpleUtils.toString(o, prefix)
    local s = "{\n"
    for key, value in pairs(o) do
        local valueString = valueToString(value, prefix)
        s = s .. prefix .. "\"" .. key .. "\": \"" .. valueString .. "\",\n"
    end
    s = s .. "\n}\n"
    return s
end

function SimpleUtils.printToString(label, o)
    print(label .. ": " .. SimpleUtils.toString(o, " "))
end

function SimpleUtils.getRandomNumbers(min, max, count)
    return SimpleUtils.debugFunc(function()
        local rangeLength = max - min + 1
        --print("rangeLength: " .. rangeLength)
        if rangeLength < count then
            print("Invalid args for SimpleUtils.getRandomNumbers: " .. tostring(min) .. " > " .. tostring(max))
            return {}
        end
        local range = {}
        for i = min, max do
            table.insert(range, i)
            --print("range insert " .. tostring(i))
        end

        local output = {}
        for _ = 0, count - 1 do
            local nextNumberIndex = math.random(1, rangeLength)
            --print("nextNumberIndex " .. tostring(nextNumberIndex))
            local nextNumber = table.remove(range, nextNumberIndex)
            --print("removed nextNumber " .. tostring(nextNumber))
            table.insert(output, nextNumber)
            rangeLength = rangeLength - 1
        end
        return output
    end, "SimpleUtils.getRandomNumbers(min=" .. tostring(min) .. ", max=" .. tostring(max) .. ", count=" .. tostring(count) .. ")")
end
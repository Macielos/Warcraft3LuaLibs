ScreenplayFactory = {
    screenplayBuilders = {}
}

--[[
    Creates an actor to be used in screenplay dialog lines. You can either create your actors every time in the beginning
    of a screenplay or create them all on map init and store in some global variable
]]
function ScreenplayFactory.createActor(unit, customName)
    local actor = ScreenplaySystem.actor:new()
    actor:assign(unit, customName)
    return actor
end

--[[
    Alternatively you can have an actor without actual unit
]]
function ScreenplayFactory.createActorFromType(unitType, player, customName)
    local actor = ScreenplaySystem.actor:new()
    actor:assignByType(unitType, player, customName)
    return actor
end

--[[
    Stores a screenplay builder function under a given name. The function will be called when starting a scene by name.
]]
function ScreenplayFactory:saveBuilder(name, screenplayBuilderFunction)
    SimpleUtils.debugFunc(function()
        if (ScreenplayFactory.screenplayBuilders[name]) then
            printWarn("Duplicate screenplay key " .. name .. ", previous one will be overriden")
        end
        ScreenplaySystem.printDebug("Saving screenplay builder " .. tostring(name))
        ScreenplayFactory.screenplayBuilders[name] = screenplayBuilderFunction
    end, "ScreenplayFactory.saveBuilder " .. tostring(name))
end

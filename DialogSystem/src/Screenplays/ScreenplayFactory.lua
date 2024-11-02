ScreenplayFactory = {
    screenplayBuilders = {}
}

do

    --- Creates an actor to be used in screenplay dialog lines. You can either create your actors every time in the beginning
    --- of a screenplay or create them all on map init and store in some global variables
    ---@param unit unit
    ---@param customName string
    ---@return ScreenplaySystem.actor
    function ScreenplayFactory:createActor(unit, customName)
        local self = ScreenplaySystem.actor:new()
        self.unit = unit
        if customName then
            self.name = customName
        else
            self.name = GetUnitName(unit)
        end
    end

    --- Alternatively if you don't want to create a unit, you can also assign unit type and player to an actor, optionally with custom name
    --- Of course, with such actors camera panning, unit flashes and animations are not available
    ---@param unitType number
    ---@param player player
    ---@param customName string
    ---@return ScreenplaySystem.actor
    function ScreenplayFactory:createActorFromType(unitType, player, customName)
        local self = ScreenplaySystem.actor:new()
        self.unitType = unitType
        self.player = player
        if customName then
            self.name = customName
        else
            self.name = GetObjectName(unitType)
        end
    end

    local function printDebug(msg)
        if ScreenplaySystem.debug then
            print(msg)
        end
    end

    --- Stores a screenplay builder function under a given name. The function will be called when starting a scene by name.
    ---@param name string
    ---@param screenplayBuilderFunction function
    function ScreenplayFactory:saveBuilder(name, screenplayBuilderFunction)
        if (ScreenplayFactory.screenplayBuilders[name]) then
            SimpleUtils.printWarn("Duplicate screenplay key " .. name .. ", previous one will be overriden")
        end
        printDebug("Saving screenplay builder " .. tostring(name))
        ScreenplayFactory.screenplayBuilders[name] = screenplayBuilderFunction
    end

end
if Debug then Debug.beginFile "SelectionTracker" end
do
    local loadBugTrigger = CreateTrigger()
    local containerFrame = nil -- framehandle
    local frames = {} -- framehandle array
    local group = CreateGroup()
    local units = {} -- unit array
    local unitsCount = 0
    local selectedUnitsOrderedFilter -- filterfunc
    
    local debug = false

    local function printDebug(msg)
        if debug == true then
            print(msg)
        end
    end

    SelectionTracker = {}

    local function GetUnitOrderValue (u)
        --heroes use the handleId
        if IsUnitType(u, UNIT_TYPE_HERO) then
            return GetHandleId(u)
        else
            --units use unitCode
            return GetUnitTypeId(u)
        end
    end

    local function selectionTrackerFilterFunction()
        local u = GetFilterUnit()
        local prio = BlzGetUnitRealField(u, UNIT_RF_PRIORITY)
        local found = false
        printDebug("FilterFunction: unit count: " .. unitsCount)
        -- compare the current u with already found, to place it in the right slot
        for loopA = 1, unitsCount do
            local priority = BlzGetUnitRealField(units[loopA], UNIT_RF_PRIORITY)
            printDebug("FilterFunction: unit " .. GetUnitName(u) .. ": priority: " .. priority .. ", unit order value " .. GetUnitOrderValue(units[loopA]))
            if priority < prio or (priority == prio and GetUnitOrderValue(units[loopA]) > GetUnitOrderValue(u)) then
                unitsCount = unitsCount + 1
                for loopB = unitsCount, loopA + 1, -1 do
                    units[loopB] = units[loopB - 1]
                end
                units[loopA] = u
                printDebug("FilterFunction: found - unit count: " .. tostring(unitsCount))
                found = true
                break
            end
        end

        -- not found add it at the end
        if not found then
            unitsCount = unitsCount + 1
            units[unitsCount] = u
        end

        printDebug("FilterFunction: NOT found - unit count: " .. tostring(unitsCount))

        u = nil
        return false
    end

    local function getSelectedUnitIndex()
        -- local player is in group selection?
        if BlzFrameIsVisible(containerFrame) then
            -- find the first visible yellow Background Frame
            for i = 0, 11 do
                if BlzFrameIsVisible(frames[i]) then
                    printDebug("GetSelectedUnitIndex: " .. tostring(i))
                    return i
                end
            end
        end
        --printDebug("GetSelectedUnitIndex: container not visible")
        return -1
    end

    local function getMainSelectedUnit(whichPlayer, index)
        printDebug("GetMainSelectedUnit: " .. tostring(index))
        GroupClear(group)
        if index >= 0 then
            GroupEnumUnitsSelected(group, whichPlayer, selectedUnitsOrderedFilter)
            local unit = units[index + 1]
            units = {}
            unitsCount = 0
            return unit
        else
            GroupEnumUnitsSelected(group, whichPlayer, nil)
            return FirstOfGroup(group)
        end
    end

    --the local current main selected unit, using it in a sync gamestate relevant manner breaks the game.
    function SelectionTracker:getMainForLocalPlayer()
        return getMainSelectedUnit(GetLocalPlayer(), getSelectedUnitIndex())
    end

    local function initFrames()
        local console = BlzGetFrameByName("ConsoleUI", 0)
        local bottomUI = FrameUtils.safeFrameGetChild(console, 1)
        containerFrame = FrameUtils.safeFrameGetChild(bottomUI, 2)
        local groupFrame = FrameUtils.safeFrameGetChild(containerFrame, 5)
        local groupSubFrame = FrameUtils.safeFrameGetChild(groupFrame, 0)

        local buttonContainer

        group = CreateGroup()
        -- give this frames a handleId
        for i = 0, BlzFrameGetChildrenCount(groupSubFrame) - 1 do
            buttonContainer = FrameUtils.safeFrameGetChild(groupSubFrame, i)
            frames[i] = FrameUtils.safeFrameGetChild(buttonContainer, 0)
        end
        DestroyTimer(GetExpiredTimer())
    end

    local function initSelectionTracker()
        selectedUnitsOrderedFilter = Filter(selectionTrackerFilterFunction)
        TimerStart(CreateTimer(), 0, false, initFrames)
        TriggerRegisterGameEvent(loadBugTrigger, EVENT_GAME_LOADED)
        TriggerAddAction(loadBugTrigger, initFrames)
    end

    OnInit.final(initSelectionTracker)
end
if Debug then Debug.endFile() end

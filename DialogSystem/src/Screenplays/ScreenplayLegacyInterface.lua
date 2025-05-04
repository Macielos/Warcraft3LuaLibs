if Debug then Debug.beginFile "ScreenplayLegacyInterface" end
--[[
Left just for compatibility reasons, because I have lots of dialogs in maps made before I renamed speak class to
ScreenplaySystem, in new maps you can just skip it
]]

speak = {}
speak.chain = {}

function speak:currentItem()
    return ScreenplaySystem:currentItem()
end

function speak:startSceneByName(name, variant, onSceneEndTrigger, interruptExisting)
    ScreenplaySystem:startSceneByName(name, variant, onSceneEndTrigger, interruptExisting)
end

function speak.chain:buildFromObject(o)
    return ScreenplaySystem.chain:buildFromObject(o)
end

function speak:goTo(index)
    ScreenplaySystem:goTo(index)
end

if Debug then Debug.endFile() end

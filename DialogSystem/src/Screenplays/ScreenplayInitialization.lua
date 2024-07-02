onInit(function()
    ScreenplaySystem:init()
end)

function loadAndInitFrames()
    utils.debugfunc(function()
        if not BlzLoadTOCFile('war3mapImported\\CustomFrameTOC.toc') then
            print("error: .fdf file failed to load")
            print("tip: are you missing a curly brace in the fdf?")
            print("tip: does the .toc file have the correct file paths?")
            print("tip: .toc files require an empty newline at the end")
        end
        ScreenplaySystem.consoleBackdrop = BlzGetFrameByName("ConsoleUIBackdrop",0)
        ScreenplaySystem.gameui    = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        ScreenplaySystem:initFrames()
        if ScreenplaySystem.initialized then
            ScreenplaySystem:refreshFrames()
            ScreenplaySystem:playCurrentItem()
        end
    end, "loadAndInitFrames")
end


-- time elapsed init.
utils.timed(0.0, function()
    loadAndInitFrames()
end)

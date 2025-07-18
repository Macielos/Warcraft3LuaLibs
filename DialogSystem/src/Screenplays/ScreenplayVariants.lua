if Debug then Debug.beginFile "ScreenplayVariants" end
--[[
    Map of screenplay configuration variants. Feel free to edit and add your own.
]]
ScreenplayVariants = {
    --[[
        An "automated" cutscene which sets cinematic mode and displays dialog lines similarly to Blizz standard
        cutscenes. Unlike standard cutscenes, this one has user controls enabled so that the player can skip single
        lines or make dialog choices. A pleasant "side effect" is that you can pause a game, save and load during cutscenes.
        Typically you still need some logic to happen on certain messages, e.g. camera movements, fadeins/fadeouts,
        units turning to each other etc., which you do by defining 'func', 'trigger' or 'actions' props of a dialog line.
        See elf screenplay in a demo map.
    ]]
    inCutsceneAutoplay = {
        anchorX = 0.565,
        anchorY = 0.08,
        width = 0.98,
        height = 0.12,
        cinematicMode = true,
        cinematicInteractive = true,
        hideUI = false,
        pauseAll = false,
        lockCamera = false,
        disableSelection = true,
        unitPan = false,
        cameraSpeed = 0.0,
        unitFlash = true,
        speed = 0.04,
        autoMoveNext = true,
        autoMoveNextDelay = 3,
        autoMoveNextDelayPerChar = 0.02,
        skippable = true,
        rewindable = true,
        interruptExisting = true,
    },
    --[[
        A modification of above that also pauses all units. Typically I use 'inCutsceneAutoplayPause' for mid-game
        cutscenes in maps with base-building. and 'inCutsceneAutoplay' for intros, outros and maps without a base.
    ]]
    inCutsceneAutoplayPause = {
        anchorX = 0.565,
        anchorY = 0.08,
        width = 0.98,
        height = 0.12,
        cinematicMode = true,
        cinematicInteractive = true,
        hideUI = false,
        pauseAll = true,
        lockCamera = false,
        disableSelection = true,
        unitPan = false,
        cameraSpeed = 0.0,
        unitFlash = true,
        speed = 0.04,
        autoMoveNext = true,
        autoMoveNextDelay = 3,
        autoMoveNextDelayPerChar = 0.02,
        skippable = true,
        rewindable = true,
        interruptExisting = true,
        enqueueIfExisting = false
    },
    --[[
        A modification of above that requires pressing right arrow to move to the next line.
    ]]
    inCutsceneNoAutoplay = {
        anchorX = 0.565, -- x-offset for dialogue box's center framepoint.
        anchorY = 0.08, -- y-offset ``.
        width = 0.98, -- 1 -- x-width of dialogue frame.
        height = 0.12, -- y-width ``.
        cinematicMode = true,
        cinematicInteractive = true,
        hideUI = false, -- should the default game ui be hidden when scenes run?
        pauseAll = false,
        lockCamera = false,
        disableSelection = true,
        unitPan = false, -- should the camera pan to the speaking actor's unit?
        cameraSpeed = 0.0, -- how fast the camera pans when scenes start/end/shift.
        unitFlash = true, -- should transmission indicators flash on the speaking unit?
        autoMoveNext = false,
        speed = 0.04, -- cadence to show new string characters (you could increase for dramatic effect).
        skippable = true,
        rewindable = true,
        interruptExisting = true,
        enqueueIfExisting = false
    },
    --[[
        A small dialog window that pauses the game and keeps the camera pointing at a currently speaking actor. Good for
        minor interactions with NPCs, merchants, dialogs without a cutscene that still require the player to make a choice
        or have several available topics to discuss.
    ]]
    inGamePause = {
        anchorX = 0.4,
        anchorY = 0.22,
        width = 0.37,
        height = 0.11,
        cinematicMode = false,
        cinematicInteractive = false,
        pauseAll = true,
        hideUI = false,
        lockCamera = true,
        disableSelection = true,
        unitPan = true,
        cameraSpeed = 0.75,
        unitFlash = true,
        autoMoveNext = true,
        autoMoveNextDelay = 3,
        speed = 0.04,
        skippable = true,
        rewindable = true,
        interruptExisting = true,
        enqueueIfExisting = false
    },
    --[[
        A simple in-game dialog that's not supposed to pause or disrupt the gameplay. Not meant for long dialogs, choices,
        etc., just quick comments or interactions in combat or when entering some new region.
    ]]
    inGame = {
        anchorX = 0.4,
        anchorY = 0.2,
        width = 0.37,
        height = 0.11,
        cinematicMode = false,
        cinematicInteractive = false,
        pauseAll = false,
        hideUI = false,
        lockCamera = false,
        disableSelection = false,
        unitPan = false,
        cameraSpeed = 0.0,
        unitFlash = true,
        autoMoveNext = true,
        autoMoveNextDelay = 3,
        speed = 0.04,
        skippable = false,
        rewindable = false,
        interruptExisting = false,
        enqueueIfExisting = true
    }
}
if Debug then Debug.endFile() end

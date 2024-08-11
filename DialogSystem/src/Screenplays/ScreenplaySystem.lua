ScreenplaySystem = {   -- main dialogue class.

    debug = false, -- print debug messages for certain functions.

    currentVariantConfig = nil,
    onSceneEndTrigger = nil,

    frameInitialized = false,

    fade = true, -- should dialogue components have fading eye candy effects?
    fadeDuration = 0.81, -- how fast to fade if fade is enabled.

    fdfBackdrop = "EscMenuBackdrop",
    fdfTitle = "CustomText", -- from imported .fdf
    fdfTextArea = "CustomTextArea", -- ``
    titleColorHex = "|cffffce22", -- character title text color.
    textColorHex = "|cffffffff", -- character speech text color.
    inactiveChoiceColorHex = "|cff808080", -- greyish text color for choices other than selected one

    messageUncoverTimer,
    trackingCameraTimer,
    autoplayTimer,
    cameraInterpolationTimer,
    delayTimer,
    fadeoutTimer,
    lastActorSpeaking,
}

ScreenplaySystem.item = {   -- sub class for dialogue strings and how they play.
    text = nil, -- the dialogue string to display.
    actor = nil, -- the actor that owns this speech item.
    anim = nil, -- play a string animation when the speech item is played.
    sound = nil, -- play a sound when this item begins.
    func = nil, -- call this function when the speech item is played (e.g. move a unit).
    trigger = nil, -- call this trigger (referred by gg_trg_TriggerName) when the speech item is played (e.g. move a unit).
    actions = {}, -- an alternative to two fields above, allows to put an entire list of itemAction objects (see below) to be executed on message
    thenGoTo = nil, -- next message index to play after the current one, defaults to current index + 1
    thenGoToFunc = nil, -- function to dynamically choose next message index to play after current one
    thenEndScene = false, -- alternatively to above, just end scene after this message
    skippable = true, -- if current item can be skipped by RIGHT arrow. NOTE: it doesn't affect skipping whole scene.
    delayText = 0, --delay before starting displaying message characters
    delayNextItem = 0, --delay after displaying all message characters, before moving to next item
    fadeInDuration = 0, --duration of fade in from black before displaying this item
    fadeOutDuration = 0, -- duration of fade out to black after displaying this item, remember to add 'fadeInDuration' to the following item or fade in by script/trigger
    skipTimers = false, --if true, upon skipping this message timed actions added via utils.skippable() will be cancelled. Set to true for messages that begin a new shot, with fade, new camera etc.
    stopOnRewind = false, --if true, rewinding a cutscene (ESC) will stop at this message
    onRewindGoTo = 0, --used to pick new message when skipping choices
}

ScreenplaySystem.itemAction = {
    func = nil,
    trigger = nil
}

ScreenplaySystem.choice = {
    text = nil, -- choice text to display
    onChoice = nil, -- function to execute after selecting a choice
    visible = true, -- whether this choice should be initially visible. Can be modified in runtime to dynamically show/hide dialog options
    visibleFunc = nil, -- additional visibility mechanism, optional function returning boolean whether this choice should be visible, note that it should not modify any state as it is called multiple times
    chosen = false, -- set by the script after selecting a choice. Can be used for conditions to show other dialog options
}

ScreenplaySystem.actor = {   -- sub class for storing actor settings.
    unit = nil, -- the unit which owns the actor object.
    name = nil, -- the name of the actor (defaults to unit name).
}
ScreenplaySystem.chain = {}  -- sub class for chaining speech items in order.

local function printDebug(msg)
    if ScreenplaySystem.debug then
        print(msg)
    end
end

-- initialize classes and class specifics:
function ScreenplaySystem:init()
    utils.newclass(ScreenplaySystem.actor)
    utils.newclass(ScreenplaySystem.item)
    utils.newclass(ScreenplaySystem.itemAction)
    utils.newclass(ScreenplaySystem.chain)
    utils.newclass(ScreenplaySystem.choice)
    self.worldui = BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0)
    self.prevActor = nil   -- control for previous actor if frames animate on change.
    self.itemFullyDisplayed = false -- flag for controlling quick-complete vs. next speech item.
    self.currentIndex = 0     -- the item currently being played from an item queue.
    self.cameraTargetX = 0     -- X coord to pan camera to.
    self.cameraTargetY = 0     -- Y coord to pan camera to.
    self.paused = false
    self.initialized = false
    self.sceneCamera = gg_cam_sceneCam
    self.trackingCameraTimer = CreateTimer()
end

function ScreenplaySystem:initFrames()
    self.fr = {}
    self.fr.backdrop = BlzCreateFrame(self.fdfBackdrop, self.gameui, 0, 0)
    self.fr.title = BlzCreateFrame(self.fdfTitle, self.fr.backdrop, 0, 0)
    self.fr.text = BlzCreateFrame(self.fdfTextArea, self.fr.backdrop, 0, 0)

    self:show(false, true)
    self.frameInitialized = true
end

function ScreenplaySystem:refreshFrames()
    BlzFrameSetSize(self.fr.backdrop, self.currentVariantConfig.width, self.currentVariantConfig.height)
    BlzFrameSetAbsPoint(self.fr.backdrop, utils.framePoints.c, self.currentVariantConfig.anchorX, self.currentVariantConfig.anchorY)

    BlzFrameSetSize(self.fr.title, self.currentVariantConfig.width, self.currentVariantConfig.height * 0.1)
    BlzFrameSetPoint(self.fr.title, utils.framePoints.tl, self.fr.backdrop, utils.framePoints.tl, self.currentVariantConfig.height * 0.2, -self.currentVariantConfig.height * 0.17)
    BlzFrameSetText(self.fr.title, "")

    BlzFrameSetSize(self.fr.text, self.currentVariantConfig.width, self.currentVariantConfig.height * 0.5)
    BlzFrameSetPoint(self.fr.text, utils.framePoints.tl, self.fr.title, utils.framePoints.tl, 0, -self.currentVariantConfig.height * 0.18)
    BlzFrameSetText(self.fr.text, "")
end

-- initialize the scene interface (e.g. typically if you are running a cinematic component first).
function ScreenplaySystem:initScene()
    self:clear()
    if self.currentVariantConfig.cinematicMode then
        CinematicModeBJ(true, GetPlayersAll())
        ClearSelection()
    end
    if self.currentVariantConfig.cinematicInteractive then
        SetUserControlForceOn(GetPlayersAll())
    end
    if self.currentVariantConfig.hideUI then
        BlzHideOriginFrames(true)
        BlzFrameSetVisible(self.consoleBackdrop, false)
    end
    if self.currentVariantConfig.disableSelection then
        BlzEnableSelections(false, false)
        EnablePreSelect(true, false)
    end
    if self.currentVariantConfig.lockCamera then
        self:enableCamera(true, false)
    end
    if self.currentVariantConfig.pauseAll then
        PauseAllUnitsBJ(true)
    end
    -- set flag for any GUI triggers that might need it:
    udg_screenplayActive = true
    self.initialized = true
end

function ScreenplaySystem:startSceneByName(name, variant, onSceneEndTrigger, interruptExisting)
    utils.debugfunc(function()
        ScreenplaySystem:startScene(self:buildScreenplay(name), variant, onSceneEndTrigger, interruptExisting)
    end, "startSceneByName " .. name .. ", " .. variant)
end


function ScreenplaySystem:buildScreenplay(name)
    return utils.debugfunc(function()
        local builder = ScreenplayFactory.screenplayBuilders[name]
        printDebug("calling builder for " .. tostring(name))
        return builder()
    end, "ScreenplayFactory.buildScreenplay " .. tostring(name))
end

function ScreenplaySystem:startScene(chain, variant, onSceneEndTrigger, interruptExisting)
    utils.debugfunc( function()
        if udg_screenplayActive == true then
            if interruptExisting == true or variant.interruptExisting == true then
                printDebug("interrupting existing scene...")
                self:clear()
                self:endScene(true)
            else
                printDebug("existing scene found, aborting...")
                return
            end
        end

        printDebug("Starting scene...")
        ClearTextMessages()

        self.currentVariantConfig = ScreenplayVariants[variant]
        self.onSceneEndTrigger = onSceneEndTrigger
        assert(self.currentVariantConfig, "invalid frame variant: " .. variant)
        self.currentIndex = 0
        self.currentChain = utils.deepCopy(chain)
        self.paused = false
        if not self.initialized then
            self:initScene()
        end
        if self.frameInitialized then
            self:refreshFrames()
        end

        if self.fade then
            self:fadeOutFrame(false)
        else
            BlzFrameSetVisible(self.fr.backdrop, true)
        end
        printDebug("calling first playNext")
        self.currentChain:playNext()
    end, "startScene")
end

function ScreenplaySystem:endScene()
    self:endScene(false)
end

-- end the dialogue sequence.
function ScreenplaySystem:endScene(sync)
    SkippableTimers:skip()
    if ScreenplaySystem.currentVariantConfig.cinematicMode then
        self:sendDummyTransmission()
    end
    if self.currentVariantConfig.cinematicMode then
        CinematicModeBJ(false, GetPlayersAll())
        ResetToGameCameraForPlayer(GetLocalPlayer(), 0)
    end
    if self.currentVariantConfig.hideUI then
        BlzHideOriginFrames(false)
        BlzFrameSetVisible(self.consoleBackdrop, true)
    end
    if self.currentVariantConfig.disableSelection then
        BlzEnableSelections(true, true)
        EnablePreSelect(true, true)
    end
    if self.fade then
        self:fadeOutFrame(true)
    else
        BlzFrameSetVisible(self.fr.backdrop, false)
    end
    if self.currentVariantConfig.pauseAll then
        printDebug("unpausing all")
        PauseAllUnitsBJ(false)
    end
    if self.currentVariantConfig.lockCamera then
        self:enableCamera(false, sync)
    end

    udg_screenplayActive = false
    self.currentIndex = 0
    self.currentChoiceIndex = 0
    self.currentChoices = nil
    self.currentVariantConfig = nil
    self.initialized = false
    if self.messageUncoverTimer then
        ReleaseTimer(self.messageUncoverTimer)
    end
    if self.autoplayTimer then
        ReleaseTimer(self.autoplayTimer)
    end
    if self.cameraInterpolationTimer then
        ReleaseTimer(self.cameraInterpolationTimer)
    end
    if self.delayTimer then
        ReleaseTimer(self.delayTimer)
    end
    if self.fadeoutTimer then
        ReleaseTimer(self.fadeoutTimer)
    end
    -- clear cache:
    if not self.paused then
        utils.destroyTable(self.currentChain)
    end
    if self.onSceneEndTrigger then
        ConditionalTriggerExecute(self.onSceneEndTrigger)
    end
end


-- @bool = true to enter dialogue camera; false to exit.
function ScreenplaySystem:enableCamera(bool, sync)
    utils.debugfunc(function()
        local cameraSpeed = utils.ifElse(sync, 0, self.currentVariantConfig.cameraSpeed)
        if bool then
            ClearTextMessagesBJ(bj_FORCE_ALL_PLAYERS)
            TimerStart(self.trackingCameraTimer, 0.03, true, function()
                utils.looplocalp(function(p)
                    CameraSetupApplyForPlayer(true, self.sceneCamera, p, cameraSpeed)
                    PanCameraToTimedForPlayer(p, self.cameraTargetX, self.cameraTargetY, cameraSpeed)
                end)
            end)
        else
            PauseTimer(self.trackingCameraTimer)
            utils.looplocalp(function(p)
                ResetToGameCameraForPlayer(p, cameraSpeed)
            end)
        end
    end, "enableCamera")
end

-- function to run when the "next" is clicked.
function ScreenplaySystem:clickNext()
    if self.currentChain then
        if ScreenplaySystem.delayTimer then
            ReleaseTimer(ScreenplaySystem.delayTimer)
            ScreenplaySystem.delayTimer = nil
            ScreenplaySystem:playCurrentItem()
        elseif ScreenplaySystem.itemFullyDisplayed then
            self.currentChain:playNext()
        else
            ScreenplaySystem.itemFullyDisplayed = true
        end
    else
        self:endScene()
    end
end


-- @bool = true to show, false to hide.
-- @skipeffectsbool = [optional] set to true skip fade animation.
function ScreenplaySystem:show(bool, skipeffectsbool)
    if bool then
        if self.fade and not skipeffectsbool then
            self:fadeOutFrame(bool)
        else
            for _, fh in pairs(self.fr) do
                if fh ~= self.fr.skipbtn then
                    BlzFrameSetVisible(fh, true)
                end
            end
        end
    else
        for _, fh in pairs(self.fr) do
            BlzFrameSetVisible(fh, false)
        end
    end
end


-- @bool = true to animate out (hide), false to animate in (show).
function ScreenplaySystem:fadeOutFrame(bool)
    utils.fadeFrame(bool, self.fr.backdrop, self.fadeDuration)
end


-- when a new chain is being played, initialize the default display.
function ScreenplaySystem:clear()
    ScreenplayUtils.clearInterpolation()
    BlzFrameSetText(self.fr.text, "")
    BlzFrameSetText(self.fr.title, "")
    if self.fade then
        BlzFrameSetAlpha(self.fr.text, 0)
        BlzFrameSetAlpha(self.fr.title, 0)
    end
end

function ScreenplaySystem:currentItem()
    return self.currentChain[self.currentIndex]
end


function ScreenplaySystem:onPreviousChoice()
    utils.debugfunc( function()
        printDebug("onPreviousChoice: ", tostring(self.currentChoiceIndex))
        if not self.currentChoiceIndex or not self.currentChoices then
            return
        end
        if self.currentChoiceIndex > 1
        then
            repeat
                self.currentChoiceIndex = self.currentChoiceIndex - 1
            until self.currentChoices[self.currentChoiceIndex]:isVisible() or self.currentChoiceIndex == 1
            self:playCurrentItem()
        end
    end, "onPreviousChoice")
end

function ScreenplaySystem:onNextChoice()
    utils.debugfunc( function()
        printDebug("onNextChoice: ", tostring(self.currentChoiceIndex))
        if not self.currentChoiceIndex or not self.currentChoices then
            return
        end
        local tableLength = utils.tableLength(self.currentChoices)
        if self.currentChoiceIndex < tableLength
        then
            repeat
                self.currentChoiceIndex = self.currentChoiceIndex + 1
            until self.currentChoices[self.currentChoiceIndex]:isVisible() or self.currentChoiceIndex == tableLength
            self:playCurrentItem()
        end
    end, "onNextChoice")
end

function ScreenplaySystem:playCurrentItem()
    --can't join choices with delayText
    self:currentItem():play()
end

function ScreenplaySystem:onSelectChoice()
    utils.debugfunc( function()
        printDebug("onSelectChoice: " .. tostring(self.currentChoiceIndex))
        if self.currentChoices then
            if self:isValidChoice() then
                printDebug("currentChoices:onChoice() - valid choice")
                self.currentChoices[self.currentChoiceIndex]:onChoice()
                self.currentChoices[self.currentChoiceIndex].chosen = true
                self.currentChoices = nil
                self.currentChoiceIndex = 0
                self.currentChain:playNextInternal()
            end
        elseif (self:canSkipItem()) then
            printDebug("will call clickNext()")
            self:clickNext()
        else
            printDebug("Couldn't select choice")
        end
    end, "onSelectChoice")
end

function ScreenplaySystem:isValidChoice()
    if self.currentChoiceIndex <= 0 then
        return false
    end
    local choice = self.currentChoices[self.currentChoiceIndex]
    return choice and choice:isVisible()
end

function ScreenplaySystem:canSkipItem()
    return self.currentVariantConfig.skippable == true and ScreenplaySystem:currentItem().skippable == true and self.fadeoutTimer == nil
end

function ScreenplaySystem:onRewind()
    utils.debugfunc( function()
        if self.currentVariantConfig.skippable == true then
            printDebug("onRewind, currentItemIndex: ", tostring(self.currentIndex))
            self.currentChain:rewind()
        end
    end, "onRewind")
end

function ScreenplaySystem:onLoad()
    utils.debugfunc( function()
        loadAndInitFrames()
        self:refreshFrames()
        self:playCurrentItem()
    end, "onLoad")
end

function ScreenplaySystem:goTo(index)
    if not self.currentChain:isValidIndex(index) then
        printWarn("Invalid goTo index " .. tostring(index) .. ", cannot proceed")
        return
    end
    self:goToInternal(index)
end

function ScreenplaySystem:goToInternal(index)
    printDebug("index " .. ScreenplaySystem.currentIndex .. " -> " .. index .. ", table length " .. utils.tableLength(ScreenplaySystem.currentChain))
    self.currentIndex = index
end

function ScreenplaySystem:sendTransmission(actor, text)
    local count = string.len(text)
    local msgLength = self.currentVariantConfig.autoMoveNextDelay + count * self.currentVariantConfig.speed * 2 --FIXME attempt to compensate diff between expected and real time of utils.timedRepeat()
    self.lastActorSpeaking = actor
    DoTransmissionBasicsXYBJ(GetUnitTypeId(actor), GetPlayerColor(GetOwningPlayer(actor)), GetUnitX(actor), GetUnitY(actor), nil, "", "", msgLength)
end

function ScreenplaySystem:sendDummyTransmission()
    if self.lastActorSpeaking then
        DoTransmissionBasicsXYBJ(GetUnitTypeId(self.lastActorSpeaking), GetPlayerColor(GetOwningPlayer(self.lastActorSpeaking)), GetUnitX(self.lastActorSpeaking), GetUnitY(self.lastActorSpeaking), nil, "", "", 0.5)
        self.lastActorSpeaking = nil
    end
end

-- @unit = assign the unit responsible for @portrait.
-- @portrait = portrait object for @unit.
function ScreenplaySystem.actor:assign(unit, customName)
    self.unit = unit
    if customName then
        self.name = customName
    else
        self.name = GetUnitName(unit)
    end
end

-- play a speech item, rendering its string characters over time and displaying actor details.
function ScreenplaySystem.item:play()
    -- initialize timer settings:
    if ScreenplaySystem.messageUncoverTimer then
        ReleaseTimer(ScreenplaySystem.messageUncoverTimer)
        ScreenplaySystem.messageUncoverTimer = nil
    end

    BlzFrameSetVisible(ScreenplaySystem.fr.backdrop, true)
    BlzFrameSetText(ScreenplaySystem.fr.title, ScreenplaySystem.titleColorHex .. self.actor.name .. "|r")
    if self.choices then
        self:playChoices()
    else
        self:playText()
    end
    -- run additional speech inputs if present:
    if ScreenplaySystem.currentVariantConfig.unitFlash then
        ScreenplayUtils.speechIndicator(self.actor.unit)
    end
    if not (self.anim == nil) then
        ResetUnitAnimation(self.actor.unit)
        QueueUnitAnimation(self.actor.unit, self.anim)
        QueueUnitAnimation(self.actor.unit, "stand")
    end
    if not (self.sound == nil) then
        utils.playSoundAll(self.sound)
    end

    BlzFrameSetVisible(ScreenplaySystem.fr.title, true)
    BlzFrameSetVisible(ScreenplaySystem.fr.text, true)
    if ScreenplaySystem.fade and ScreenplaySystem.prevActor ~= self.actor then
        utils.fadeFrame(false, ScreenplaySystem.fr.title, ScreenplaySystem.fadeDuration)
        utils.fadeFrame(false, ScreenplaySystem.fr.text, ScreenplaySystem.fadeDuration)
    end

    if ScreenplaySystem.currentVariantConfig.unitPan then
        ScreenplaySystem.cameraTargetX = GetUnitX(self.actor.unit)
        ScreenplaySystem.cameraTargetY = GetUnitY(self.actor.unit)
    end
    ScreenplaySystem.prevActor = self.actor
end

function ScreenplaySystem.item:playText()
    ScreenplaySystem.currentChoices = nil
    ScreenplaySystem.currentChoiceIndex = 0
    -- a flag for skipping the text animation:
    ScreenplaySystem.itemFullyDisplayed = false

    local count = string.len(self.text)
    local pos = 1
    local ahead = ''

    -- render string characters:
    local delay = self:getDuration()

    if ScreenplaySystem.currentVariantConfig.cinematicMode then
        ScreenplaySystem:sendTransmission(self.actor.unit, self.text)
    end

    --send msg and clear it immediately - just for the purpose of having the messages in transmission log
    DisplayTimedTextToPlayer(GetLocalPlayer(), 0.0, 0.0, 0.1, ScreenplaySystem.titleColorHex .. self.actor.name .. "|r: " .. self.text)
    ClearTextMessages()

    ScreenplaySystem.messageUncoverTimer = utils.timedRepeat(ScreenplaySystem.currentVariantConfig.speed, count, function(timer)
        if pos < count and not ScreenplaySystem.itemFullyDisplayed then
            ahead = string.sub(self.text, pos, pos + 1)
            -- scan for formatting patterns:
            if ahead == '|c' then
                pos = pos + 10
            elseif ahead == '|r' or ahead == '|n' then
                pos = pos + 2
            else
                pos = pos + 1
            end
            BlzFrameSetText(ScreenplaySystem.fr.text, ScreenplaySystem.textColorHex .. string.sub(self.text, 1, pos))
            ScreenplayUtils.fixFocus(ScreenplaySystem.fr.text)
        else
            ScreenplaySystem.itemFullyDisplayed = true
            BlzFrameSetText(ScreenplaySystem.fr.text, ScreenplaySystem.textColorHex .. self.text)
            ReleaseTimer(timer)
            if ScreenplaySystem.currentVariantConfig.autoMoveNext == true then
                ScreenplaySystem.autoplayTimer = utils.timed(delay, function()
                    ScreenplaySystem.currentChain:playNext()
                end)
            end
        end
    end)
end

function ScreenplaySystem.item:playChoices()
    local text = "";
    ScreenplaySystem.currentChoices = self.choices
    local displayedIndex = 1
    for index, choice in ipairs(ScreenplaySystem.currentChoices) do
        if choice:isVisible() then
            local color = utils.ifElse(index == ScreenplaySystem.currentChoiceIndex, ScreenplaySystem.textColorHex, ScreenplaySystem.inactiveChoiceColorHex)
            text = text .. color .. ((displayedIndex) .. ". " .. choice.text .. "|n")
            displayedIndex = displayedIndex + 1
        end
    end
    BlzFrameSetText(ScreenplaySystem.fr.text, text)
    ScreenplaySystem.itemFullyDisplayed = true
end

function ScreenplaySystem.choice:isVisible()
    return self.visible and (self.visibleFunc == nil or self.visibleFunc())
end

function ScreenplaySystem.item:getDuration()
    if not ScreenplaySystem.currentVariantConfig.autoMoveNext then
        return 0
    end
    return ScreenplaySystem.currentVariantConfig.autoMoveNextDelay + string.len(self.text) * ScreenplaySystem.currentVariantConfig.speed + self.delayNextItem + self.fadeInDuration + self.fadeOutDuration
end

-- after a speech item completes, see what needs to happen next (load next item or close, etc.)
function ScreenplaySystem.chain:playNext()
    utils.debugfunc(function()
        printDebug("playNext: currentIndex: " .. tostring(ScreenplaySystem.currentIndex))
        local fadeOutDuration
        if ScreenplaySystem:currentItem() == nil then
            fadeOutDuration = 0
        else
            fadeOutDuration = ScreenplaySystem:currentItem().fadeOutDuration
        end
        if fadeOutDuration > 0 then
            utils.fadeOut(fadeOutDuration)
            ScreenplaySystem.fadeoutTimer = utils.timed(fadeOutDuration * 1.2, function()
                self:moveAndPlayNextInternal()
            end)
        else
            self:moveAndPlayNextInternal()
        end
    end, "playNext")
end

function ScreenplaySystem.chain:moveAndPlayNextInternal()
    local nextIndex = self:getNextIndex();
    ScreenplaySystem:goToInternal(nextIndex)
    if ScreenplaySystem.messageUncoverTimer then
        ReleaseTimer(ScreenplaySystem.messageUncoverTimer)
    end
    if ScreenplaySystem.autoplayTimer then
        ReleaseTimer(ScreenplaySystem.autoplayTimer)
    end
    if ScreenplaySystem.delayTimer then
        ReleaseTimer(ScreenplaySystem.delayTimer)
    end
    self:playNextInternal()
end

function ScreenplaySystem.chain:playNextInternal()
    if ScreenplaySystem.fadeoutTimer then
        ReleaseTimer(ScreenplaySystem.fadeoutTimer)
        ScreenplaySystem.fadeoutTimer = nil
    end
    if not self:isValidIndex(ScreenplaySystem.currentIndex) then
        ScreenplaySystem:clear()
        ScreenplaySystem:endScene()
    else
        local currentItem = self[ScreenplaySystem.currentIndex]
        if currentItem == nil or currentItem.skipTimers == true then
            SkippableTimers:skip()
        end
        if not self[ScreenplaySystem.currentIndex] or not self[ScreenplaySystem.currentIndex].actor.unit or IsUnitDeadBJ(self[ScreenplaySystem.currentIndex].actor.unit) then
            -- if next item was set to nil or is empty, try to skip over:
            self:playNext()
        else
            if self[ScreenplaySystem.currentIndex].func and not self[ScreenplaySystem.currentIndex].text then
                self[ScreenplaySystem.currentIndex]:func()
                self:playNext()
            else
                printDebug("trying to play index item: " .. ScreenplaySystem.currentIndex .. " with actor: " .. self[ScreenplaySystem.currentIndex].actor.name)

                ScreenplaySystem.currentChoiceIndex = 0
                local currentItem = self[ScreenplaySystem.currentIndex]
                if currentItem.trigger then
                    ConditionalTriggerExecute(currentItem.trigger)
                end
                if currentItem.func then
                    currentItem:func()
                end
                if currentItem.actions then
                    for index, action in ipairs(currentItem.actions) do
                        if action.func then
                            action:func()
                        end
                        if action.trigger then
                            ConditionalTriggerExecute(action.trigger)
                        end
                    end
                end

                local initialDelay = currentItem.delayText + currentItem.fadeInDuration

                if initialDelay > 0 then
                    if currentItem.fadeInDuration > 0 then
                        utils.fadeIn(currentItem.fadeInDuration)
                    end

                    BlzFrameSetVisible(ScreenplaySystem.fr.backdrop, false)
                    ScreenplaySystem:sendDummyTransmission()
                    ScreenplaySystem.delayTimer = utils.timed(initialDelay, function()
                        ScreenplaySystem.delayTimer = nil
                        currentItem:play()
                    end)
                    printDebug("delayed playing index item: " .. tostring(ScreenplaySystem.currentIndex))
                else
                    currentItem:play()
                    printDebug("played index item: " .. tostring(ScreenplaySystem.currentIndex))
                end

            end
        end
    end
end

function ScreenplaySystem.chain:getNextIndex()
    return self:getNextIndexForIndex(ScreenplaySystem.currentIndex);
end

function ScreenplaySystem.chain:getNextIndexForIndex(index)
    if self[index] then
        if self[index].thenEndScene == true then
           return -1
        elseif self[index].thenGoTo then
            return self[index].thenGoTo
        elseif self[index].thenGoToFunc then
            return self[index].thenGoToFunc()
        elseif self[index].choices ~= nil and self[index].onRewindGoTo ~= nil then
            return self[index].onRewindGoTo
        else
            return index + 1
        end
    else
        return index + 1
    end
end


function ScreenplaySystem.chain:rewind()
    local currentIndex = ScreenplaySystem.currentIndex;
    printDebug("Rewind - current index: " .. tostring(currentIndex))
    if currentIndex == nil then
        return
    end
    if self[currentIndex].choices ~= nil and self[currentIndex].onRewindGoTo == nil then
        return
    end
    local tableLength = utils.tableLength(ScreenplaySystem.currentChain)
    local prevIndex
    repeat
        prevIndex = currentIndex
        currentIndex = self:getNextIndexForIndex(currentIndex)
        printDebug("Skip - moving from " .. tostring(prevIndex) .. " to " .. tostring(currentIndex))
    until currentIndex <= 0
            or currentIndex > tableLength
            or currentIndex == ScreenplaySystem.currentIndex
            or (self[currentIndex].choices ~= nil and self[currentIndex].onRewindGoTo == nil)
            or self[currentIndex].stopOnRewind == true
    if currentIndex == ScreenplaySystem.currentIndex then
        printWarn("Cycle detected on index " .. currentIndex .. ", this dialog will never end, can't rewind")
        return
    end

    ScreenplaySystem:goToInternal(currentIndex)
    self:moveAndPlayNextInternal()
end

function ScreenplaySystem.chain:buildFromObject(buildFrom)
    assert(buildFrom and buildFrom[1], "error: ScreenplaySystem.chain:buildFromObject is missing an index-value table argument.")
    local newChain = ScreenplaySystem.chain:new()

    for itemIndex, item in pairs(buildFrom) do
        printDebug("building pair " .. tostring(itemIndex) .. ": " .. tostring(item.text) .. ", " .. tostring(item.choices))
        assert(item.text or item.choices, "error in item " .. itemIndex .. ": text or choices must not be empty")
        assert(item.actor, "error in item " .. itemIndex .. ": actor must not be empty")
        newChain[itemIndex] = ScreenplaySystem.item:new()
        if item.text then
            newChain[itemIndex].text = item.text
        end
        newChain[itemIndex].actor = item.actor
        if item.emotion then
            newChain[itemIndex].emotion = item.emotion
        end
        if item.anim then
            newChain[itemIndex].anim = item.anim
        end
        if item.sound then
            newChain[itemIndex].sound = item.sound
        end
        if item.delayText then
            newChain[itemIndex].delayText = item.delayText
        else
            newChain[itemIndex].delayText = 0
        end
        if item.delayNextItem then
            newChain[itemIndex].delayNextItem = item.delayNextItem
        else
            newChain[itemIndex].delayNextItem = 0
        end
        if item.func then
            newChain[itemIndex].func = item.func
        end
        if item.trigger then
            newChain[itemIndex].trigger = item.trigger
        end
        if item.thenGoTo then
            newChain[itemIndex].thenGoTo = item.thenGoTo
        end
        if not (item.thenEndScene == nil) then
            newChain[itemIndex].thenEndScene = item.thenEndScene
        end
        if item.thenGoToFunc then
            newChain[itemIndex].thenGoToFunc = item.thenGoToFunc
        end
        if not (item.skippable == nil) then
            newChain[itemIndex].skippable = item.skippable
        end
        if not (item.interruptExisting == nil) then
            newChain[itemIndex].interruptExisting = item.interruptExisting
        else
            newChain[itemIndex].interruptExisting = false
        end
        if not (item.fadeOutDuration == nil) then
            newChain[itemIndex].fadeOutDuration = item.fadeOutDuration
        end
        if not (item.fadeInDuration == nil) then
            newChain[itemIndex].fadeInDuration = item.fadeInDuration
        end
        if not (item.skipTimers == nil) then
            newChain[itemIndex].skipTimers = item.skipTimers
        end
        if not (item.stopOnRewind == nil) then
            newChain[itemIndex].stopOnRewind = item.stopOnRewind
        end
        if not (item.onRewindGoTo == nil) then
            newChain[itemIndex].onRewindGoTo = item.onRewindGoTo
        end
        if item.choices then
            newChain[itemIndex].choices = {}
            for choiceIndex, choiceBuildFrom in pairs(item.choices) do
                printDebug("building choice " .. choiceIndex .. ": " .. choiceBuildFrom.text .. ", visible: " .. tostring(choiceBuildFrom.visible))
                local choice = ScreenplaySystem.choice:new()
                choice.text = choiceBuildFrom.text
                choice.onChoice = choiceBuildFrom.onChoice
                if not (choiceBuildFrom.visible == nil) then
                    choice.visible = choiceBuildFrom.visible
                else
                    choice.visible = true
                end
                if not (choiceBuildFrom.visibleFunc == nil) then
                    choice.visibleFunc = choiceBuildFrom.visibleFunc
                end
                choice.chosen = false
                newChain[itemIndex].choices[choiceIndex] = choice
            end
        end
    end
    return newChain
end

-- @item  = add this item as the next item in the chain.
-- @index = [optional] insert @item into this index location instead.
function ScreenplaySystem.chain:add(item, index)
    if index then
        table.insert(self, index, item)
    else
        self[#self + 1] = item
    end
end


-- @item = remove this item from the chain (accepts item object or the index location in the chain).
function ScreenplaySystem.chain:remove(item)
    -- remove by index:
    if type(item) == "number" then
        table.remove(self, item)
        -- remove by value:
    else
        for i, v in ipairs(self) do
            if v == item then
                table.remove(self, i)
            end
        end
    end
end

function ScreenplaySystem.chain:isValidIndex(index)
    return index > 0 and index <= utils.tableLength(self)
end

function ScreenplaySystem:isActive()
    return udg_screenplayActive
end
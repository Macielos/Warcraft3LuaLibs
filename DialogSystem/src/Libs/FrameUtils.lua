FrameUtils = {
    FRAME_POINTS = { -- shorthand 'FRAMEPOINT' for terser code.
        tl = FRAMEPOINT_TOPLEFT,
        t = FRAMEPOINT_TOP,
        tr = FRAMEPOINT_TOPRIGHT,
        r = FRAMEPOINT_RIGHT,
        br = FRAMEPOINT_BOTTOMRIGHT,
        b = FRAMEPOINT_BOTTOM,
        bl = FRAMEPOINT_BOTTOMLEFT,
        l = FRAMEPOINT_LEFT,
        c = FRAMEPOINT_CENTER,
    }
}

-- @bool = true to fade out (hide); false to fade in (show).
function FrameUtils.fadeFrame(fade, frame, duration)
    BlzFrameSetVisible(frame, true)
    local bool = fade
    local alpha = 255
    local int = math.floor(255 / math.floor(duration / 0.03))
    -- show:
    if bool then
        BlzFrameSetVisible(frame, true)
        BlzFrameSetAlpha(frame, 255)
        SimpleUtils.timedRepeat(0.03, nil, function(timer)
            if BlzFrameGetAlpha(frame) > 0 and BlzFrameGetAlpha(frame) > int then
                alpha = alpha - int
                BlzFrameSetAlpha(frame, alpha)
            else
                BlzFrameSetAlpha(frame, 0)
                BlzFrameSetVisible(frame, false)
                ReleaseTimer(timer)
            end
        end)
        -- hide:
    else
        BlzFrameSetVisible(frame, true)
        BlzFrameSetAlpha(frame, 0)
        SimpleUtils.timedRepeat(0.03, nil, function(timer)
            if BlzFrameGetAlpha(frame) ~= 255 and BlzFrameGetAlpha(frame) < 255 - int then
                alpha = alpha + int
                BlzFrameSetAlpha(frame, alpha)
            else
                BlzFrameSetAlpha(frame, 255)
                BlzFrameSetVisible(frame, true)
                ReleaseTimer(timer)
            end
        end)
    end
end


function FrameUtils.printFrameStructure(frame)
    print("STRUCTURE OF FRAME " .. BlzFrameGetName(frame) .. ": ")
    local childrenCount = BlzFrameGetChildrenCount(frame)
    print("  CHILDREN COUNT: " .. tostring(childrenCount))
    for i = 0, childrenCount do
        print("  CHILD " .. tostring(i) .. ": " .. BlzFrameGetName(BlzFrameGetChild(frame, i)))
    end
end

function FrameUtils.getChildByName(parent, expectedChildName)
    local childrenCount = BlzFrameGetChildrenCount(parent)
    for i = 0, childrenCount do
        local child = BlzFrameGetChild(parent, i)
        local childName = BlzFrameGetName(child)
        if childName == expectedChildName then
            return child
        end
    end
end


function FrameUtils.fixFocus(fh)
    BlzFrameSetEnable(fh, false)
    BlzFrameSetEnable(fh, true)
end


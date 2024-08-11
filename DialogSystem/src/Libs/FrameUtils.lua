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
function FrameUtils.fadeFrame(bool, fh, dur)
    BlzFrameSetVisible(fh, true)
    local bool = bool
    local fh = fh
    local alpha = 255
    local int = math.floor(255 / math.floor(dur / 0.03))
    -- show:
    if bool then
        BlzFrameSetVisible(fh, true)
        BlzFrameSetAlpha(fh, 255)
        SimpleUtils.timedRepeat(0.03, nil, function(timer)
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
        SimpleUtils.timedRepeat(0.03, nil, function(timer)
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

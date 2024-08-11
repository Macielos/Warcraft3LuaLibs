function ReleaseTimer(whichTimer)
    PauseTimer(whichTimer)
    DestroyTimer(whichTimer)
end

function printWarn(msg)
    print("[WARN] " .. msg)
end

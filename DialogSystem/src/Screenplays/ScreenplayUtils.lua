if Debug then Debug.beginFile "ScreenplayUtils" end
ScreenplayUtils = {} -- utility class with functions you can use in your screenplays
ScreenplayUtils.debug = false

function ScreenplayUtils.interpolateCameraFromCurrentTillEndOfCurrentItem(cameraTo)
    return ScreenplayUtils.interpolateCameraFromCurrent(cameraTo, ScreenplayUtils.getCurrentItemDuration())
end

function ScreenplayUtils.interpolateCameraFromCurrent(cameraTo, duration)
    return ScreenplayUtils.interpolateCamera(GetCurrentCameraSetup(), cameraTo, duration)
end

function ScreenplayUtils.interpolateCameraTillEndOfCurrentItem(cameraFrom, cameraTo)
    ScreenplayUtils.interpolateCamera(cameraFrom, cameraTo, ScreenplayUtils.getCurrentItemDuration())
end

function ScreenplayUtils.interpolateCamera(cameraFrom, cameraTo, duration)
    ScreenplayUtils.clearInterpolation()
    CameraSetupApply(cameraFrom, true)
    local cameraFromX = CameraSetupGetDestPositionX(cameraFrom)
    local cameraFromY = CameraSetupGetDestPositionY(cameraFrom)
    local cameraFromDistance = CameraSetupGetField(cameraFrom, CAMERA_FIELD_TARGET_DISTANCE)

    local cameraToX = CameraSetupGetDestPositionX(cameraTo)
    local cameraToY = CameraSetupGetDestPositionY(cameraTo)
    if(cameraToX == cameraFromX and cameraFromY == cameraToY) then
        --ugly workaround for blizz camera getting unlocked when positions from == to
        cameraFromY = cameraFromY - 5.0;
    end

    SetCameraPosition(cameraFromX, cameraFromY)
    SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, cameraFromDistance, 0.0)

    CameraSetupApplyForceDuration(cameraTo, true, duration)
    local timer = CreateTimer()
    ScreenplaySystem.cameraInterpolationTimer = timer
    local durationInt = math.floor(duration)
    local durationLeft = durationInt
    TimerStart(timer, 1.0, true, function()
        --print("durationLeft: " .. tostring(durationLeft) .. " / " .. tostring(durationInt))
        durationLeft = durationLeft - 1
        if durationLeft <= 0 then
            CameraSetupApplyForceDuration(cameraTo, true, 9999)
            SimpleUtils.releaseTimer(timer)
        else
            local interpolatedX = ScreenplayUtils.interpolate(cameraFromX, cameraToX, (durationInt - durationLeft) / durationInt)
            local interpolatedY = ScreenplayUtils.interpolate(cameraFromY, cameraToY, (durationInt - durationLeft) / durationInt)
            local interpolatedDistance = ScreenplayUtils.interpolate(CameraSetupGetField(cameraFrom, CAMERA_FIELD_TARGET_DISTANCE), CameraSetupGetField(cameraTo, CAMERA_FIELD_TARGET_DISTANCE), (durationInt - durationLeft) / durationInt)
            local sceneCameraX = GetCameraTargetPositionX()
            local sceneCameraY = GetCameraTargetPositionY()
            local sceneCameraDistance = GetCameraField(CAMERA_FIELD_TARGET_DISTANCE)
            local ERROR_MARGIN = 5.0
            --local ERROR_MARGIN_ANGLE = 1.0
            local fixed = false
            if math.abs(sceneCameraX - interpolatedX) > ERROR_MARGIN or math.abs(sceneCameraY - interpolatedY) > ERROR_MARGIN then
                if ScreenplaySystem.debug then
                    print("interpolateCamera: " .. tostring(interpolatedX) .. ", " .. tostring(interpolatedY))
                    print("sceneCamera: " .. tostring(sceneCameraX) .. ", " .. tostring(sceneCameraY))
                    print("fixing camera pos")
                end
                --CameraSetupSetDestPosition(speak.scenecam, interpolatedX, interpolatedY)
                SetCameraPosition(interpolatedX, interpolatedY)
                fixed = true
            end
            if math.abs(sceneCameraDistance - interpolatedDistance) > ERROR_MARGIN then
                if ScreenplaySystem.debug then
                    print("fixing camera distance" .. tostring(sceneCameraDistance) .. " -> " .. interpolatedDistance)
                end
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, interpolatedDistance, 0.0)
                fixed = true
            end
            if fixed == true then
                CameraSetupApplyForceDuration(cameraTo, true, durationLeft)
            end
        end
    end)
    return timer
end

function ScreenplayUtils.interpolate(from, to, fraction)
    return from + (to - from) * fraction
end

function ScreenplayUtils.clearInterpolation()
    if ScreenplaySystem.cameraInterpolationTimer then
        SimpleUtils.releaseTimer(ScreenplaySystem.cameraInterpolationTimer)
    end
    StopCamera()
end

function ScreenplayUtils.getCurrentItemDuration()
    local currentItem = ScreenplaySystem:currentItem()
    if currentItem == nil then
        return 0.0
    end
    return currentItem:getDuration()
end
if Debug then Debug.endFile() end

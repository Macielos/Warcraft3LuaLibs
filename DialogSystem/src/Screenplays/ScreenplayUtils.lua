ScreenplayUtils = {}
ScreenplayUtils.debug = false

function ScreenplayUtils.speechIndicator(unit)
    UnitAddIndicatorBJ(unit, 0.00, 100, 0.00, 0)
end

function ScreenplayUtils.fixFocus(fh)
    BlzFrameSetEnable(fh, false)
    BlzFrameSetEnable(fh, true)
end

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
    return SimpleUtils.debugFunc(function()
        ScreenplayUtils.clearInterpolation()
        CameraSetupApply(cameraFrom, true)
        local cameraFromX = CameraSetupGetDestPositionX(cameraFrom)
        local cameraFromY = CameraSetupGetDestPositionY(cameraFrom)
        local cameraFromDistance = CameraSetupGetField(cameraFrom, CAMERA_FIELD_TARGET_DISTANCE)

        SetCameraPosition(cameraFromX, cameraFromY)
        SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, cameraFromDistance, 0.0)

        CameraSetupApplyForceDuration(cameraTo, true, duration)
        local timer = CreateTimer()
        ScreenplaySystem.cameraInterpolationTimer = timer
        local durationInt = math.floor(duration)
        local durationLeft = durationInt
        TimerStart(timer, 1.0, true, function()
            SimpleUtils.debugFunc(function()
                --print("durationLeft: " .. tostring(durationLeft) .. " / " .. tostring(durationInt))
                durationLeft = durationLeft - 1
                if durationLeft <= 0 then
                    CameraSetupApplyForceDuration(cameraTo, true, 9999)
                    ReleaseTimer(timer)
                else
                    local interpolatedX = ScreenplayUtils.interpolate(CameraSetupGetDestPositionX(cameraFrom), CameraSetupGetDestPositionX(cameraTo), (durationInt - durationLeft) / durationInt)
                    local interpolatedY = ScreenplayUtils.interpolate(CameraSetupGetDestPositionY(cameraFrom), CameraSetupGetDestPositionY(cameraTo), (durationInt - durationLeft) / durationInt)
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
            end, "interpolateCamera timer")
        end)
        return timer
    end, "interpolateCamera")
end

function ScreenplayUtils.interpolate(from, to, fraction)
    return from + (to - from) * fraction
end

function ScreenplayUtils.clearInterpolation()
    if ScreenplaySystem.cameraInterpolationTimer then
        ReleaseTimer(ScreenplaySystem.cameraInterpolationTimer)
    end
    StopCamera()
end

function ScreenplayUtils.getCurrentItemDuration()
    return SimpleUtils.debugFunc(function()
        return ScreenplaySystem:currentItem():getDuration()
    end, "getCurrentItemDuration")
end

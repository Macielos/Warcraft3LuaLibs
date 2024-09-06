SkippableTimers = {
    skippableTimers = {}
}

function SkippableTimers:start(dur, func)
    local timer = SimpleUtils.timed(dur, func)
    table.insert(self.skippableTimers, timer)
    return timer
end

function SkippableTimers:skip()
    for index, timer in ipairs(self.skippableTimers) do
        SimpleUtils.releaseTimer(timer)
    end
    self.skippableTimers = {}
end
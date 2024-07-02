SkippableTimers = {
    skippableTimers = {}
}

function SkippableTimers:start(dur, func)
    local timer = utils.timed(dur, func)
    table.insert(self.skippableTimers, timer)
    return timer
end

function SkippableTimers:skip()
    for index, timer in ipairs(self.skippableTimers) do
        ReleaseTimer(timer)
    end
    self.skippableTimers = {}
end
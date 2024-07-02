ScreenplayFactory:saveBuilder("dwarf", function()
    return ScreenplaySystem.chain:buildFromObject({
        [1] = {
            text = "Hey, lad. Good time drinkin' with ya! Until the next time!",
            actor = actorDwarf,
        },
        [2] = {
            text = "Yeeeeah, s-s-s-sure thing, pal!",
            actor = actorFootman,
        },
    })
end)
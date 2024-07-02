ScreenplayFactory:saveBuilder("elfBeer", function()
    return ScreenplaySystem.chain:buildFromObject({
        [1] = {
            text = "Heh, I just knew this priest wouldn't speak this Holy Light bullcrap sober.",
            actor = actorFootman,
        },
    })
end)
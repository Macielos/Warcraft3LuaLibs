ScreenplayFactory:saveBuilder("orcBeer", function()
    return ScreenplaySystem.chain:buildFromObject({
        [1] = {
            text = "Ahh, there you have a camp, hummies. Gotta tell the warchief. Here's your beer, loser. Enjoy it... while you can, hehehe.",
            actor = actorGrunt,
        },
    })
end)
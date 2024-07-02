ScreenplayFactory:saveBuilder("intro", function()
    return ScreenplaySystem.chain:buildFromObject({
        [1] = {
            text = "Ahhh, the world's spinning! What did this fucking dwarf pour me!? Gotta find some beer.",
            actor = actorFootman,
        },
    })
end)
ScreenplayFactory:saveBuilder("elf", function()
    return ScreenplaySystem.chain:buildFromObject({
        [1] = {
            delayText = 2.0,
            text = "Greeting, noble warrior. I am a priest and can enlighten you so you can fully embrace the Holy Light on your path. Holy light blablala holy light blablala holy light blablala holy light blabla (you may wanna skip that or check if scrolling works) blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala holy light blablala ",
            actor = actorElf,
            func = function()
                ScreenplayUtils.interpolateCamera(gg_cam_elf01a, gg_cam_elf01b, 90)
            end,
        },
        [2] = {
            text = "Ssssscrew this. Got anything to drink, longear?",
            actor = actorFootman,
        },
        [3] = {
            text = "I do not think you should drink anymore. Allow me to cast Dispel on you so that you are sober again.",
            actor = actorElf,
        },
        [4] = {
            text = "What!? No, no, don't you dare, inhuman beast!",
            actor = actorFootman,
            trigger = gg_trg_Scene_Elf_Cast_Dispel,
            fadeOutDuration = 1.0,
        },
        [5] = {
            fadeInDuration = 1.0,
            delayText = 2.0,
            text = "Hahahahaha, your foul magic doesn't work on me, inhuman! I'm still drunk! And I wanna drink even more!",
            actor = actorFootman,
            fadeOutDuration = 2.0,
            func = function()
                ScreenplayUtils.interpolateCamera(gg_cam_elf02a, gg_cam_elf02b, 30)
            end
        },
    })
end)

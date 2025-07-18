if Debug then Debug.beginFile "InitDemoSoundSets" end
do
    local REYNART = FourCC('H000')
    local INALKA = FourCC('H001')

    local KNIVES = FourCC('AEfk')
    local SHIFT = FourCC('AEbl')
    local STEALTH = FourCC('AOwk')
    local LIQUIDATION = FourCC('ANfd')

    local PREFIX = 'war3mapImported\\'

    local function addSoundSet(unitId, filePrefix)
        print('addSoundSet ' .. filePrefix)
        UnitSoundSets:addUnitSoundSet(unitId, PREFIX .. filePrefix)
    end

    local function addAbilitySoundSet(unitId, abilityId, filePrefix)
        print('addAbilitySoundSet ' .. filePrefix)
        UnitSoundSets:addUnitAbilitySingleSound(unitId, abilityId, PREFIX .. filePrefix)
    end

    function InitDemoSoundSets()
        print('InitDemoSoundSets START')
        addSoundSet(REYNART, 'Reynart')
        addSoundSet(INALKA, 'Akama')
        addAbilitySoundSet(INALKA, KNIVES, 'InalkaKnives1')
        addAbilitySoundSet(INALKA, SHIFT, 'InalkaShift1')
        addAbilitySoundSet(INALKA, STEALTH, 'InalkaStealth1')
        addAbilitySoundSet(INALKA, LIQUIDATION, 'InalkaLiquidation1')
        print('InitDemoSoundSets DONE')
    end
end

if Debug then Debug.endFile() end

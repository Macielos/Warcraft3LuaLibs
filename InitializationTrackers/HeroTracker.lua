Debug.beginFile "HeroTracker"
--MUST BE PUT AFTER UNIT TRACKER
do
    UnitTracker:register('heroes', function(unit)
        return IsUnitHero(unit)
    end)
end
Debug.endFile()
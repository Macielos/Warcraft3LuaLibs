if Debug then Debug.beginFile "OnInit" end
do
    local funcs = {}

    function onInit(code)
        if type(code) == "function" then
            table.insert(funcs, code)
        end
    end

    local old = InitBlizzard
    function InitBlizzard()
        old()

        for i = 1, #funcs do
            funcs[i]()
        end

        funcs = nil
    end
end
if Debug then Debug.endFile() end

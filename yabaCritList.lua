function yaba:addToCritList(spellName, val)
    -- list was empty until now
    if (yaba_critList.spellName == nil and yaba_critList.value == nil) then
        yaba_critList = yaba:newNode(spellName, val)
        return true

    else
        local it = yaba_critList
        --compare with first value
        if (it.spellName == spellName) then
            -- Maybe later refactor to avoid duplicate code
            if (it.value < val) then
                it.value = val
                return true
            end
            do
                return
            end
        end

        --compare with subsequent values
        while not (it.nextNode == nil) do
            it = it.nextNode
            if (it.spellName == spellName) then
                if (it.value < val) then
                    it.value = val
                    return true
                end
                do
                    return
                end
            end
        end

        --add spell if not found till now
        it.nextNode = yaba:newNode(spellName, val)
        return true
    end

end

function yaba:newNode(spellName, val)
    local newNode = {};
    newNode.spellName = spellName
    newNode.value = val
    newNode.nextNode = nil
    return newNode
end

function yaba:clearCritList()
    yaba_critList = {};
    print(yaba_color .. "Critlist cleared");
end

function yaba:listCrits()
    if not (yaba_critList.value == nil) then
        print(yaba_color .. "Highest crits:");
        local it = yaba_critList
        print(yaba_color .. it.spellName .. ": " .. it.value)
        while not (it.nextNode == nil) do
            it = it.nextNode
            print(yaba_color .. it.spellName .. ": " .. it.value)
        end
    else
        print(yaba_color .. "No crits recorded");
    end
end

function yaba:reportCrits()
    if not (yaba_critList.value == nil) then
        for _, v in pairs(yaba_outputChannelList) do
            if v == "Print" then
                print(yaba_color .. "Highest crits:");
                local it = yaba_critList
                print(yaba_color .. it.spellName .. ": " .. it.value)
                while not (it.nextNode == nil) do
                    it = it.nextNode
                    print(yaba_color .. it.spellName .. ": " .. it.value)
                end
            elseif (v == "Officer") then
                if (CanEditOfficerNote()) then
                    yaba:ReportToChannel(v)
                end
            elseif (v == "Battleground") then
                inInstance, instanceType = IsInInstance()
                if (instanceType == "pvp") then
                    yaba:ReportToChannel("INSTANCE_CHAT")
                end
            elseif (v == "Party") then
                if IsInGroup() then
                    yaba:ReportToChannel(v);
                end
            elseif (v == "Raid" or v == "Raid_Warning") then
                if IsInRaid() then
                    yaba:ReportToChannel(v);
                end
            elseif (v == "Whisper") then
                for _, w in pairs(yaba_whisperList) do
                    SendChatMessage("Highest crits:", "WHISPER", "COMMON", w)
                    local it = yaba_critList
                    SendChatMessage(it.spellName .. ": " .. it.value, "WHISPER", "COMMON", w)
                    while not (it.nextNode == nil) do
                        it = it.nextNode
                        SendChatMessage(it.spellName .. ": " .. it.value, "WHISPER", "COMMON", w)
                    end
                end
            elseif (v == "Sound DMG") then
                -- do nothing
            elseif (v == "Sound Heal") then
                -- do nothing
            else
                yaba:ReportToChannel(v);
            end
        end
    else
        print(yaba_color .. "No crits recorded");
    end
end

function yaba:ReportToChannel(channelName)
    SendChatMessage("Highest crits:", channelName)
    local it = yaba_critList
    SendChatMessage(it.spellName .. ": " .. it.value, channelName)
    while not (it.nextNode == nil) do
        it = it.nextNode
        SendChatMessage(it.spellName .. ": " .. it.value, channelName)
    end
end

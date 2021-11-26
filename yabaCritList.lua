function SBM:addToCritList(spellName, val)
    -- list was empty until now
    if (SBM_critList.spellName == nil and SBM_critList.value == nil) then
        SBM_critList = SBM:newNode(spellName, val)
        return true

    else
        local it = SBM_critList
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
        it.nextNode = SBM:newNode(spellName, val)
        return true
    end

end

function SBM:newNode(spellName, val)
    local newNode = {};
    newNode.spellName = spellName
    newNode.value = val
    newNode.nextNode = nil
    return newNode
end

function SBM:clearCritList()
    SBM_critList = {};
    print(SBM_color .. "Critlist cleared");
end

function SBM:listCrits()
    if not (SBM_critList.value == nil) then
        print(SBM_color .. "Highest crits:");
        local it = SBM_critList
        print(SBM_color .. it.spellName .. ": " .. it.value)
        while not (it.nextNode == nil) do
            it = it.nextNode
            print(SBM_color .. it.spellName .. ": " .. it.value)
        end
    else
        print(SBM_color .. "No crits recorded");
    end
end

function SBM:reportCrits()
    if not (SBM_critList.value == nil) then
        for _, v in pairs(SBM_outputChannelList) do
            if v == "Print" then
                print(SBM_color .. "Highest crits:");
                local it = SBM_critList
                print(SBM_color .. it.spellName .. ": " .. it.value)
                while not (it.nextNode == nil) do
                    it = it.nextNode
                    print(SBM_color .. it.spellName .. ": " .. it.value)
                end
            elseif (v == "Officer") then
                if (CanEditOfficerNote()) then
                    SBM:ReportToChannel(v)
                end
            elseif (v == "Battleground") then
                inInstance, instanceType = IsInInstance()
                if (instanceType == "pvp") then
                    SBM:ReportToChannel("INSTANCE_CHAT")
                end
            elseif (v == "Party") then
                if IsInGroup() then
                    SBM:ReportToChannel(v);
                end
            elseif (v == "Raid" or v == "Raid_Warning") then
                if IsInRaid() then
                    SBM:ReportToChannel(v);
                end
            elseif (v == "Whisper") then
                for _, w in pairs(SBM_whisperList) do
                    SendChatMessage("Highest crits:", "WHISPER", "COMMON", w)
                    local it = SBM_critList
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
                SBM:ReportToChannel(v);
            end
        end
    else
        print(SBM_color .. "No crits recorded");
    end
end

function SBM:ReportToChannel(channelName)
    SendChatMessage("Highest crits:", channelName)
    local it = SBM_critList
    SendChatMessage(it.spellName .. ": " .. it.value, channelName)
    while not (it.nextNode == nil) do
        it = it.nextNode
        SendChatMessage(it.spellName .. ": " .. it.value, channelName)
    end
end
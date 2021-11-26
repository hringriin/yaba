local _, ns = ...
SBM = ns

-- Function for event filter for CHAT_MSG_SYSTEM to suppress message of player on whisper list being offline when being whispered to
function SBM_suppressWhisperMessage(_, _, msg, _, ...)
    -- TODO Suppression only works for Portuguese, English, German and French because they have the same naming format.
    -- See https://www.townlong-yak.com/framexml/live/GlobalStrings.lua
    local textWithoutName = msg:gsub("%'%a+%'", ""):gsub("  ", " ")

    localizedPlayerNotFoundStringWithoutName = ERR_CHAT_PLAYER_NOT_FOUND_S:gsub("%'%%s%'", ""):gsub("  ", " ")

    if not (textWithoutName == localizedPlayerNotFoundStringWithoutName) then
        return false
    end

    local name = string.gmatch(msg, "%'%a+%'")

    -- gmatch returns iterator.
    for w in name do
        name = w
    end
    if not (name == nil) then
        name = name:gsub("'", "")
    else
        return false
    end

    local isNameInWhisperList = false
    for _, w in pairs(SBM_whisperList) do
        if (w == name) then
            isNameInWhisperList = true
        end
    end
    return isNameInWhisperList

end

function SBM:BAM_OnLoad(self)
    SlashCmdList["BAM"] = function(cmd)
        local params = {}
        local i = 1
        for arg in string.gmatch(cmd, "%S+") do
            params[i] = arg
            i = i + 1
        end
        SBM:bam_cmd(params)
    end
    SLASH_BAM1 = '/bam'
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SBM_suppressWhisperMessage)

    --math.randomseed(os.time())
end

function SBM:eventHandler(_, event, arg1)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then

        SBM:combatLogEvent()
    elseif event == "ADDON_LOADED" and arg1 == "SvensBamAddon" then
        SBM_icon = nil -- Needs to be initialized to be saved
        SBM:loadAddon() -- in SvensBamAddonConfig.lua
    end
end

function SBM:combatLogEvent()
    local name, _ = UnitName("player");
    local eventType, _, _, eventSource, _, _, _, enemyName = select(2, CombatLogGetCurrentEventInfo())
    if not (eventSource == name) then
        do
            return
        end
    end

    --Assign correct values to variables
    if (eventType == "SPELL_DAMAGE") then
        spellName, _, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(13, CombatLogGetCurrentEventInfo())
    elseif (eventType == "SPELL_HEAL") then
        spellName, _, amount, overheal, school, critical = select(13, CombatLogGetCurrentEventInfo())
    elseif (eventType == "RANGE_DAMAGE") then
        spellName, _, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(13, CombatLogGetCurrentEventInfo())
    elseif (eventType == "SWING_DAMAGE") then
        spellName = "Autohit"
        amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
    end

    if (amount ~= nil and amount < SBM_threshold and SBM_threshold ~= 0) then
        do
            return
        end
    end

    for i = 1, #SBM_eventList do
        if (eventType == SBM_eventList[i].eventType and SBM_eventList[i].boolean and critical == true) then
            newMaxCrit = SBM:addToCritList(spellName, amount);
            if (SBM_onlyOnNewMaxCrits and not newMaxCrit) then
                do
                    return
                end
            end
            local output


            if eventType == "SPELL_HEAL" then
                output = SBM_outputHealMessage:gsub("(SN)", spellName):gsub("(SD)", amount):gsub("TN", enemyName)
            else
                local returnString = SBM:mySuperRandomFunction(SBM_outputDamageMessage);
                output = returnString:gsub("(SN)", spellName):gsub("(SD)", amount):gsub("TN", enemyName)
            end
            for _, v in pairs(SBM_outputChannelList) do
                if v == "Print" then
                    print(SBM_color .. output)
                elseif (v == "Say" or v == "Yell") then
                    local inInstance, _ = IsInInstance()
                    if (inInstance) then
                        SendChatMessage(output, v);
                    end
                elseif (v == "Battleground") then
                    local _, instanceType = IsInInstance()
                    if (instanceType == "pvp") then
                        SendChatMessage(output, "INSTANCE_CHAT")
                    end
                elseif (v == "Officer") then
                    if (CanEditOfficerNote()) then
                        SendChatMessage(output, v)
                    end
                elseif (v == "Raid" or v == "Raid_Warning") then
                    if IsInRaid() then
                        SendChatMessage(output, v);
                    end
                elseif (v == "Party") then
                    if IsInGroup() then
                        SendChatMessage(output, v);
                    end
                elseif (v == "Whisper") then
                    for _, w in pairs(SBM_whisperList) do
                        SendChatMessage(output, "WHISPER", "COMMON", w)
                    end
                elseif (v == "Sound DMG") then
                    if (eventType ~= "SPELL_HEAL") then
                        SBM:playRandomSoundFromList(SBM_soundfileDamage)
                    end
                elseif (v == "Sound Heal") then
                    if (eventType == "SPELL_HEAL") then
                        SBM:playRandomSoundFromList(SBM_soundfileHeal)
                    end
                elseif (v == "Do Train Emote") then
                    DoEmote("train");
                else
                    SendChatMessage(output, v);
                end
            end
        end
    end
end

function SBM:mySuperRandomFunction(testString)
  local array = { }

  for str in string.gmatch(testString, "[^;]+") do
    table.insert(array, str)
  end

  local counter = 0

  for _ in pairs(array) do
    counter = counter + 1
  end

  return array[math.random(1,counter)]
end

function SBM:bam_cmd(params)
    cmd = params[1]
    if (cmd == "help" or cmd == "") then
        print(SBM_color .. "Possible parameters:")
        print(SBM_color .. "list: lists highest crits of each spell")
        print(SBM_color .. "report: report highest crits of each spell to channel list")
        print(SBM_color .. "clear: delete list of highest crits")
        print(SBM_color .. "config: Opens config page")
    elseif (cmd == "list") then
        SBM:listCrits();
    elseif (cmd == "report") then
        SBM:reportCrits();
    elseif (cmd == "clear") then
        SBM:clearCritList();
    elseif (cmd == "config") then
        -- For some reason, needs to be called twice to function correctly on first call
        InterfaceOptionsFrame_OpenToCategory(SvensBamAddonConfig.panel)
        InterfaceOptionsFrame_OpenToCategory(SvensBamAddonConfig.panel)
    elseif (cmd == "test") then
        print(SBM_color .. "Function not implemented")
    else
        print(SBM_color .. "Bam Error: Unknown command")
    end
end

function SBM:playRandomSoundFromList(listOfFilesAsString)
    SBM_soundFileList = {}
    for arg in string.gmatch(listOfFilesAsString, "%S+") do
        table.insert(SBM_soundFileList, arg)
    end
    local randomIndex = random(1, #SBM_soundFileList)
    PlaySoundFile(SBM_soundFileList[randomIndex])
end

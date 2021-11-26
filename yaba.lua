local _, ns = ...
yaba = ns

-- Function for event filter for CHAT_MSG_SYSTEM to suppress message of player on whisper list being offline when being whispered to
function yaba_suppressWhisperMessage(_, _, msg, _, ...)
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
    for _, w in pairs(yaba_whisperList) do
        if (w == name) then
            isNameInWhisperList = true
        end
    end
    return isNameInWhisperList

end

function yaba:OnLoad(self)
    SlashCmdList["BAM"] = function(cmd)
        local params = {}
        local i = 1
        for arg in string.gmatch(cmd, "%S+") do
            params[i] = arg
            i = i + 1
        end
        yaba:cmd(params)
    end
    SLASH_BAM1 = '/yaba'
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", yaba_suppressWhisperMessage)
end

function yaba:eventHandler(_, event, arg1)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then

        yaba:combatLogEvent()
    elseif event == "ADDON_LOADED" and arg1 == "yaba" then
        yaba_icon = nil -- Needs to be initialized to be saved
        yaba:loadAddon() -- in yabaConfig.lua
    end
end

function yaba:combatLogEvent()
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

    if (amount ~= nil and amount < yaba_threshold and yaba_threshold ~= 0) then
        do
            return
        end
    end

    for i = 1, #yaba_eventList do
        if (eventType == yaba_eventList[i].eventType and yaba_eventList[i].boolean and critical == true) then
            newMaxCrit = yaba:addToCritList(spellName, amount);
            if (yaba_onlyOnNewMaxCrits and not newMaxCrit) then
                do
                    return
                end
            end
            local output


            if eventType == "SPELL_HEAL" then
                output = yaba_outputHealMessage:gsub("(SN)", spellName):gsub("(SD)", amount):gsub("TN", enemyName)
            else
                local returnString = yaba:mySuperRandomFunction(yaba_outputDamageMessage);
                output = returnString:gsub("(SN)", spellName):gsub("(SD)", amount):gsub("TN", enemyName)
            end
            for _, v in pairs(yaba_outputChannelList) do
                if v == "Print" then
                    print(yaba_color .. output)
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
                    for _, w in pairs(yaba_whisperList) do
                        SendChatMessage(output, "WHISPER", "COMMON", w)
                    end
                elseif (v == "Sound DMG") then
                    if (eventType ~= "SPELL_HEAL") then
                        yaba:playRandomSoundFromList(yaba_soundfileDamage)
                    end
                elseif (v == "Sound Heal") then
                    if (eventType == "SPELL_HEAL") then
                        yaba:playRandomSoundFromList(yaba_soundfileHeal)
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

function yaba:mySuperRandomFunction(testString)
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

function yaba:cmd(params)
  cmd = params[1]
  if (cmd == "" or cmd == nil or cmd == "help") then
    print(yaba_color .. "Possible parameters:")
    print(yaba_color .. "- list: Lists highest crits of each spell")
    print(yaba_color .. "- report: Report highest crits of each spell to channel list")
    print(yaba_color .. "- clear: Delete list of highest crits")
    print(yaba_color .. "- config: Opens config page")
    print(yaba_color .. "- addDmg: Adds a single sentence to the list of critical hits.")
    print(yaba_color .. "- addHeal: Adds a single sentence to the list of critical heals.")
    print(yaba_color .. "- rmDmg: Removes a single sentence from the list of critical hits.")
    print(yaba_color .. "- rmHeal: Removes a single sentence from the list of critical heals.")
    print(yaba_color .. "- clearDmg: Clears all sentences from the list of critical hits.")
    print(yaba_color .. "- clearHeal: Clears all sentences from the list of critical heals.")
    print(yaba_color .. "- verbose: If set to 'True', play a sound and print a message on every crit, if 'False' play only on new record.")
  elseif (cmd == "list") then
    yaba:listCrits();
  elseif (cmd == "report") then
    yaba:reportCrits();
  elseif (cmd == "clear") then
    yaba:clearCritList();
  elseif (cmd == "config") then
    -- For some reason, needs to be called twice to function correctly on first call
    InterfaceOptionsFrame_OpenToCategory(yabaConfig.panel)
    InterfaceOptionsFrame_OpenToCategory(yabaConfig.panel)
  elseif ( cmd == "addDmg") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  elseif ( cmd == "addHeal") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  elseif ( cmd == "rmDmg") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  elseif ( cmd == "rmHeal") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  elseif ( cmd == "clearDmg") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  elseif ( cmd == "clearHeal") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  elseif ( cmd == "verbose") then
    print(yaba_color .. "Function not (yet) implemented: " .. cmd)
  else
    print(yaba_color .. "I see you have no clue what you're doing here ;-)")
  end
end

function yaba:playRandomSoundFromList(listOfFilesAsString)
    yaba_soundFileList = {}
    for arg in string.gmatch(listOfFilesAsString, "%S+") do
        table.insert(yaba_soundFileList, arg)
    end
    local randomIndex = random(1, #yaba_soundFileList)
    PlaySoundFile(yaba_soundFileList[randomIndex])
end

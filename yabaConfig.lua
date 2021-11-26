local SBM_ldb = LibStub("LibDataBroker-1.1")

function SBM:loadAddon()
    local channelButtonList = {}
    local eventButtonList = {}
    local channelList = {
        "Say",
        "Yell",
        "Print",
        "Guild",
        "Raid",
        "Emote",
        "Party",
        "Officer",
        "Raid_Warning",
        "Battleground",
        "Whisper",
        "Sound DMG",
        "Sound Heal",
        "Do Train Emote"
    }

    if (SBM_onlyOnNewMaxCrits == nil) then
        SBM_onlyOnNewMaxCrits = false
    end

    if (SBM_MinimapSettings == nil) then
        SBM_MinimapSettings = {
            hide = false,
        }
    end

    if (SBM_color == nil) then
        SBM_color = "|cff" .. "94" .. "CF" .. "00"
    end

    if (SBM_threshold == nil) then
        SBM_threshold = 0
    end

    if (SBM_soundfileDamage == nil) then
        SBM_soundfileDamage = "Interface\\AddOns\\yaba\\bam.ogg"
    end

    if (SBM_soundfileHeal == nil) then
        SBM_soundfileHeal = "Interface\\AddOns\\yaba\\bam.ogg"
    end

    local rgb = {
        { color = "Red", value = SBM_color:sub(5, 6) },
        { color = "Green", value = SBM_color:sub(7, 8) },
        { color = "Blue", value = SBM_color:sub(9, 10) }
    }

    if (SBM_whisperList == nil) then
        SBM_whisperList = {}
    end

    local defaultEventList = {
        { name = "Spell Damage", eventType = "SPELL_DAMAGE", boolean = true },
        { name = "Ranged", eventType = "RANGE_DAMAGE", boolean = true },
        { name = "Melee Autohit", eventType = "SWING_DAMAGE", boolean = true },
        { name = "Heal", eventType = "SPELL_HEAL", boolean = true },
    }

    --reset SBM_eventList in case defaultEventList was updated
    if (SBM_eventList == nil or not (#SBM_eventList == #defaultEventList)) then
        SBM_eventList = defaultEventList
    end

    if (SBM_critList == nil) then
        SBM_critList = {}
    end

    if (SBM_outputDamageMessage == nil) then
        SBM_outputDamageMessage = "BAM! SN SD!"
        SBM_outputChannelList = { "Print", "Sound DMG", "Sound Heal" } -- Reset to fix problems in new version
    end

    if (SBM_outputHealMessage == nil) then
        SBM_outputHealMessage = "BAM! SN SD!"
        SBM_outputChannelList = { "Print", "Sound DMG", "Sound Heal" } -- Reset to fix problems in new version
    end

    if (SBM_outputChannelList == nil) then
        SBM_outputChannelList = { "Print", "Sound DMG", "Sound Heal" }
    end

    --Good Guide https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/FrameXML/InterfaceOptionsFrame.lua
    --Options Main Menu
    yabaConfig = {};
    yabaConfig.panel = CreateFrame("Frame", "yabaConfig", UIParent);
    yabaConfig.panel.name = "Svens Bam Addon";
    yabaConfig.panel.title = yabaConfig.panel:CreateFontString("GeneralOptionsDescription", "OVERLAY");
    yabaConfig.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaConfig.panel.title:SetPoint("TOPLEFT", 5, -5);
    yabaConfig.panel.title:SetJustifyH("LEFT")


    --Channel Options SubMenu
    yabaChannelOptions = {}
    yabaChannelOptions.panel = CreateFrame("Frame", "yabaChannelOptions");
    yabaChannelOptions.panel.name = "Channel options";
    yabaChannelOptions.panel.parent = "Svens Bam Addon"
    yabaChannelOptions.panel.okay = function()
        SBM:saveWhisperList()
        SBM:saveSoundfile()
    end
    SBM:populateChannelSubmenu(channelButtonList, channelList)

    --General Options SubMenu NEEDS TO BE LAST BECAUSE SLIDERS CHANGE FONTSTRINGS OF ALL MENUS
    yabaGeneralOptions = {}
    yabaGeneralOptions.panel = CreateFrame("Frame", "yabaGeneralOptions");
    yabaGeneralOptions.panel.name = "General options";
    yabaGeneralOptions.panel.parent = "Svens Bam Addon"
    yabaGeneralOptions.panel.okay = function()
        SBM:saveDamageOutputList()
        SBM:saveHealOutputList()
        SBM:saveSoundfileDamage()
        SBM:saveSoundfileHeal()
        SBM:saveThreshold()
    end
    SBM:populateGeneralSubmenu(eventButtonList, SBM_eventList, rgb)

    --Set order of Menus here
    InterfaceOptions_AddCategory(yabaConfig.panel);
    InterfaceOptions_AddCategory(yabaGeneralOptions.panel);
    InterfaceOptions_AddCategory(yabaChannelOptions.panel);

    print(SBM_color .. "Svens Bam Addon loaded! Type /bam help for options!")
end

function SBM:populateGeneralSubmenu(eventButtonList, SBM_eventList, rgb)

    local lineHeight = 16
    local boxHeight = 32
    local boxSpacing = 24 -- Even though a box is 32 high, it somehow takes only 24 of space
    local editBoxWidth = 400
    local categoryPadding = 16
    local baseYOffSet = 5

    local categoryCounter = 0 -- increase after each category
    local amountLinesWritten = 0 -- increase after each Font String
    local boxesPlaced = 0 -- increase after each edit box or check box placed

    -- Output Messages
    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("OutputDamageMessageDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1

    SBM:createOutputDamageMessageEditBox(boxHeight, editBoxWidth, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing))
    boxesPlaced = boxesPlaced + 1
    categoryCounter = categoryCounter + 1

    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("OutputHealMessageDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1

    SBM:createOutputHealMessageEditBox(boxHeight, editBoxWidth, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing))
    boxesPlaced = boxesPlaced + 1

    -- Damage Threshold
    categoryCounter = categoryCounter + 1
    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("ThresholdDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1

    SBM:createThresholdEditBox(-(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing))
    boxesPlaced = boxesPlaced + 1

    -- Event Types to Trigger
    categoryCounter = categoryCounter + 1
    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("EventTypeDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1

    for i = 1, #SBM_eventList do
        SBM:createEventTypeCheckBoxes(i, 1, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing), eventButtonList, SBM_eventList)
        boxesPlaced = boxesPlaced + 1
    end

    -- Trigger Options
    categoryCounter = categoryCounter + 1
    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("OnlyOnMaxCritsDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1

    SBM:createTriggerOnlyOnCritRecordCheckBox(1, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing))
    boxesPlaced = boxesPlaced + 1

    -- Minimap Button
    categoryCounter = categoryCounter + 1
    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("OtherOptionsDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1

    SBM:createMinimapShowOptionCheckBox(1, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing))
    boxesPlaced = boxesPlaced + 1
    categoryCounter = categoryCounter + 1

    -- Color changer
    yOffSet = 3
    yabaGeneralOptions.panel.title = yabaGeneralOptions.panel:CreateFontString("FontColorDescription", "OVERLAY");
    yabaGeneralOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaGeneralOptions.panel.title:SetPoint("TOPLEFT", 5, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing));
    amountLinesWritten = amountLinesWritten + 1
    amountLinesWritten = amountLinesWritten + 1 --Another Time, because the Sliders have on line above
    for i = 1, 3 do
        SBM:createColorSlider(i, yabaGeneralOptions.panel, rgb, -(baseYOffSet + categoryCounter * categoryPadding + amountLinesWritten * lineHeight + boxesPlaced * boxSpacing))
    end
    categoryCounter = categoryCounter + 1


end

function SBM:createEventTypeCheckBoxes(i, x, y, eventButtonList, SBM_eventList)
    local checkButton = CreateFrame("CheckButton", "yaba_EventTypeCheckButton" .. i, yabaGeneralOptions.panel, "UICheckButtonTemplate")
    eventButtonList[i] = checkButton
    checkButton:ClearAllPoints()
    checkButton:SetPoint("TOPLEFT", x * 32, y)
    checkButton:SetSize(32, 32)

    _G[checkButton:GetName() .. "Text"]:SetText(SBM_eventList[i].name)
    _G[checkButton:GetName() .. "Text"]:SetFont(GameFontNormal:GetFont(), 14, "NONE")
    if (SBM_eventList[i].boolean) then
        eventButtonList[i]:SetChecked(true)
    end

    eventButtonList[i]:SetScript("OnClick", function()
        if eventButtonList[i]:GetChecked() then
            SBM_eventList[i].boolean = true
        else
            SBM_eventList[i].boolean = false
        end
    end)

end

function SBM:createOutputDamageMessageEditBox(height, width, y)
    outputDamageMessageEditBox = SBM:createEditBox("OutputDamageMessage", yabaGeneralOptions.panel, height, width)
    outputDamageMessageEditBox:SetPoint("TOPLEFT", 40, y)
    outputDamageMessageEditBox:Insert(SBM_outputDamageMessage)
    outputDamageMessageEditBox:SetCursorPosition(0)
    outputDamageMessageEditBox:SetScript("OnEscapePressed", function(...)
        outputDamageMessageEditBox:ClearFocus()
        outputDamageMessageEditBox:SetText(SBM_outputDamageMessage)
    end)
    outputDamageMessageEditBox:SetScript("OnEnterPressed", function(...)
        outputDamageMessageEditBox:ClearFocus()
        SBM:saveDamageOutputList()
    end)
    outputDamageMessageEditBox:SetScript("OnEnter", function(...)
        GameTooltip:SetOwner(outputDamageMessageEditBox, "ANCHOR_BOTTOM");
        GameTooltip:SetText("Insert your damage message here.\nSN will be replaced with spell name,\nSD with spell damage,\nTN with enemy name.\nDefault: BAM! SN SD!")
        GameTooltip:ClearAllPoints()
        GameTooltip:Show()
    end)
    outputDamageMessageEditBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function SBM:createOutputHealMessageEditBox(height, width, y)
    outputHealMessageEditBox = SBM:createEditBox("OutputHealMessage", yabaGeneralOptions.panel, height, width)
    outputHealMessageEditBox:SetPoint("TOPLEFT", 40, y)
    outputHealMessageEditBox:Insert(SBM_outputHealMessage)
    outputHealMessageEditBox:SetCursorPosition(0)
    outputHealMessageEditBox:SetScript("OnEscapePressed", function(...)
        outputHealMessageEditBox:ClearFocus()
        outputHealMessageEditBox:SetText(SBM_outputHealMessage)
    end)
    outputHealMessageEditBox:SetScript("OnEnterPressed", function(...)
        outputHealMessageEditBox:ClearFocus()
        SBM:saveHealOutputList()
    end)
    outputHealMessageEditBox:SetScript("OnEnter", function(...)
        GameTooltip:SetOwner(outputHealMessageEditBox, "ANCHOR_BOTTOM");
        GameTooltip:SetText("Insert your heal message here.\nSN will be replaced with spell name,\nSD with spell damage,\nTN with enemy name.\nDefault: BAM! SN SD!")
        GameTooltip:ClearAllPoints()
        GameTooltip:Show()
    end)
    outputHealMessageEditBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function SBM:createThresholdEditBox(y)
    thresholdEditBox = SBM:createEditBox("ThresholdEditBox", yabaGeneralOptions.panel, 32, 400)
    thresholdEditBox:SetPoint("TOPLEFT", 40, y)
    thresholdEditBox:Insert(SBM_threshold)
    thresholdEditBox:SetCursorPosition(0)
    thresholdEditBox:SetScript("OnEscapePressed", function(...)
        thresholdEditBox:ClearFocus()
        thresholdEditBox:SetText(SBM_threshold)
    end)
    thresholdEditBox:SetScript("OnEnterPressed", function(...)
        thresholdEditBox:ClearFocus()
        SBM:saveThreshold()
    end)
    thresholdEditBox:SetScript("OnEnter", function(...)
        GameTooltip:SetOwner(thresholdEditBox, "ANCHOR_BOTTOM");
        GameTooltip:SetText("Damage or heal must be at least this high to trigger bam!\nSet 0 to trigger on everything.")
        GameTooltip:ClearAllPoints()
        GameTooltip:Show()
    end)
    thresholdEditBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function SBM:createTriggerOnlyOnCritRecordCheckBox(x, y)
    local checkButton = CreateFrame("CheckButton", "OnlyOnMaxCritCheckBox", yabaGeneralOptions.panel, "UICheckButtonTemplate")
    checkButton:ClearAllPoints()
    checkButton:SetPoint("TOPLEFT", x * 32, y)
    checkButton:SetSize(32, 32)
    OnlyOnMaxCritCheckBoxText:SetText("Only trigger on new crit record")
    OnlyOnMaxCritCheckBoxText:SetFont(GameFontNormal:GetFont(), 14, "NONE")

    if (SBM_onlyOnNewMaxCrits) then
        OnlyOnMaxCritCheckBox:SetChecked(true)
    end

    OnlyOnMaxCritCheckBox:SetScript("OnClick", function()
        if OnlyOnMaxCritCheckBox:GetChecked() then
            SBM_onlyOnNewMaxCrits = true
        else
            SBM_onlyOnNewMaxCrits = false
        end
    end)
end

function SBM:createMinimapShowOptionCheckBox(x, y)
    local checkButton = CreateFrame("CheckButton", "MinimapShowOptionButtonCheckBox", yabaGeneralOptions.panel, "UICheckButtonTemplate")
    checkButton:ClearAllPoints()
    checkButton:SetPoint("TOPLEFT", x * 32, y)
    checkButton:SetSize(32, 32)
    MinimapShowOptionButtonCheckBoxText:SetText("Show Minimap Button")
    MinimapShowOptionButtonCheckBoxText:SetFont(GameFontNormal:GetFont(), 14, "NONE")

    if (SBM_MinimapSettings.hide == false) then
        MinimapShowOptionButtonCheckBox:SetChecked(true)
        SBM:createMinimapButton()
    end

    MinimapShowOptionButtonCheckBox:SetScript("OnClick", function()
        if MinimapShowOptionButtonCheckBox:GetChecked() then
            SBM_MinimapSettings.hide = false
            if (LibDBIcon10_SBM_dataObject == nil) then
                SBM:createMinimapButton()
            else
                LibDBIcon10_SBM_dataObject:Show()
            end
        else
            LibDBIcon10_SBM_dataObject:Hide()
            SBM_MinimapSettings.hide = true
        end
    end)
end

function SBM:populateChannelSubmenu(channelButtonList, channelList)
    yabaChannelOptions.panel.title = yabaChannelOptions.panel:CreateFontString("OutputChannelDescription", "OVERLAY");
    yabaChannelOptions.panel.title:SetFont(GameFontNormal:GetFont(), 14, "NONE");
    yabaChannelOptions.panel.title:SetPoint("TOPLEFT", 5, -5);
    -- Checkboxes channels and Edit Box for whispers
    for i = 1, #channelList do
        SBM:createCheckButtonChannel(i, 1, i, channelButtonList, channelList)
    end
    SBM:createResetChannelListButton(yabaChannelOptions.panel, channelList, channelButtonList)
end

function SBM:createCheckButtonChannel(i, x, y, channelButtonList, channelList)
    local YOffset = y * -24
    local checkButton = CreateFrame("CheckButton", "yaba_ChannelCheckButton" .. i, yabaChannelOptions.panel, "UICheckButtonTemplate")
    channelButtonList[i] = checkButton
    checkButton:ClearAllPoints()
    checkButton:SetPoint("TOPLEFT", x * 32, YOffset)
    checkButton:SetSize(32, 32)

    _G[checkButton:GetName() .. "Text"]:SetText(channelList[i])
    _G[checkButton:GetName() .. "Text"]:SetFont(GameFontNormal:GetFont(), 14, "NONE")
    for j = 1, #SBM_outputChannelList do
        if (SBM_outputChannelList[j] == channelList[i]) then
            channelButtonList[i]:SetChecked(true)
        end
    end

    channelButtonList[i]:SetScript("OnClick", function()
        if channelButtonList[i]:GetChecked() then
            table.insert(SBM_outputChannelList, channelList[i])
        else
            indexOfFoundValues = {}
            for j = 1, #SBM_outputChannelList do
                if (SBM_outputChannelList[j] == channelList[i]) then
                    table.insert(indexOfFoundValues, j)
                end
            end
            j = #indexOfFoundValues
            while (j > 0) do
                table.remove(SBM_outputChannelList, indexOfFoundValues[j])
                j = j - 1;
            end
        end
    end)

    -- Create Edit Box for whispers
    if (channelList[i] == "Whisper") then
        whisperFrame = SBM:createEditBox("WhisperList", yabaChannelOptions.panel, 32, 400)
        whisperFrame:SetPoint("TOP", 50, -24 * y)
        for _, v in pairs(SBM_whisperList) do
            whisperFrame:Insert(v .. " ")
        end
        whisperFrame:SetCursorPosition(0)

        whisperFrame:SetScript("OnEscapePressed", function(...)
            whisperFrame:ClearFocus()
            whisperFrame:SetText("")
            for _, v in pairs(SBM_whisperList) do
                whisperFrame:Insert(v .. " ")
            end
        end)
        whisperFrame:SetScript("OnEnterPressed", function(...)
            whisperFrame:ClearFocus()
            SBM:saveWhisperList()
        end)
        whisperFrame:SetScript("OnEnter", function(...)
            GameTooltip:SetOwner(whisperFrame, "ANCHOR_BOTTOM");
            GameTooltip:SetText("Separate names of people you want to whisper to with spaces.")
            GameTooltip:ClearAllPoints()
            GameTooltip:Show()
        end)
        whisperFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- Create Edit Box for Damage Soundfile and reset button
    if (channelList[i] == "Sound DMG") then
        local soundfileDamageFrameXOffset = 50
        local soundfileDamageFrameHeight = 32
        local soundfileDamageFrameWidth = 400
        soundfileDamageFrame = SBM:createEditBox("SoundfileDamage", yabaChannelOptions.panel, soundfileDamageFrameHeight, soundfileDamageFrameWidth)
        soundfileDamageFrame:SetPoint("TOP", soundfileDamageFrameXOffset, YOffset)

        soundfileDamageFrame:Insert(SBM_soundfileDamage)

        soundfileDamageFrame:SetCursorPosition(0)

        soundfileDamageFrame:SetScript("OnEscapePressed", function(...)
            soundfileDamageFrame:ClearFocus()
            soundfileDamageFrame:SetText("")
            soundfileDamageFrame:Insert(SBM_soundfileDamage)
        end)
        soundfileDamageFrame:SetScript("OnEnterPressed", function(...)
            soundfileDamageFrame:ClearFocus()
            SBM:saveSoundfileDamage()
        end)
        soundfileDamageFrame:SetScript("OnEnter", function(...)
            GameTooltip:SetOwner(soundfileDamageFrame, "ANCHOR_BOTTOM");
            GameTooltip:SetText("Specify sound file path, beginning from your WoW _classic_ folder.\n"
                    .. "If you copy a sound file to your World of Warcraft folder, you have to restart the client before that file works!\n"
                    .. "You can enter multiple file paths separated by spaces. Bam Addon will then play a random sound of that list.")
            GameTooltip:ClearAllPoints()
            GameTooltip:Show()
        end)
        soundfileDamageFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        local resetSoundfileButtonWidth = 56
        SBM:createResetSoundfileDamageButton(yabaChannelOptions.panel, resetSoundfileButtonWidth, soundfileDamageFrameWidth / 2 + soundfileDamageFrameXOffset + resetSoundfileButtonWidth / 2, YOffset, soundfileDamageFrameHeight)
    end

    -- Create Edit Box for Heal Soundfile and reset button
    if (channelList[i] == "Sound Heal") then
        local soundfileHealFrameXOffset = 50
        local soundfileHealFrameHeight = 32
        local soundfileHealFrameWidth = 400
        soundfileHealFrame = SBM:createEditBox("SoundfileHeal", yabaChannelOptions.panel, soundfileHealFrameHeight, soundfileHealFrameWidth)
        soundfileHealFrame:SetPoint("TOP", soundfileHealFrameXOffset, YOffset)

        soundfileHealFrame:Insert(SBM_soundfileHeal)

        soundfileHealFrame:SetCursorPosition(0)

        soundfileHealFrame:SetScript("OnEscapePressed", function(...)
            soundfileHealFrame:ClearFocus()
            soundfileHealFrame:SetText("")
            soundfileHealFrame:Insert(SBM_soundfileHeal)
        end)
        soundfileHealFrame:SetScript("OnEnterPressed", function(...)
            soundfileHealFrame:ClearFocus()
            SBM:saveSoundfileHeal()
        end)
        soundfileHealFrame:SetScript("OnEnter", function(...)
            GameTooltip:SetOwner(soundfileHealFrame, "ANCHOR_BOTTOM");
            GameTooltip:SetText("Specify sound file path, beginning from your WoW _classic_ folder.\n"
                    .. "If you copy a sound file to your World of Warcraft folder, you have to restart the client before that file works!\n"
                    .. "You can enter multiple file paths separated by spaces. Bam Addon will then play a random sound of that list.")
            GameTooltip:ClearAllPoints()
            GameTooltip:Show()
        end)
        soundfileHealFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        local resetSoundfileButtonWidth = 56
        SBM:createResetSoundfileHealButton(yabaChannelOptions.panel, resetSoundfileButtonWidth, soundfileHealFrameWidth / 2 + soundfileHealFrameXOffset + resetSoundfileButtonWidth / 2, YOffset, soundfileHealFrameHeight)
    end
end

function SBM:createResetSoundfileDamageButton(parentFrame, resetSoundfileButtonWidth, x, y, soundfileDamageFrameHeight)
    local resetSoundfileButtonHeight = 24
    resetChannelListButton = CreateFrame("Button", "ResetSoundfileDamage", parentFrame, "UIPanelButtonTemplate");
    resetChannelListButton:ClearAllPoints()
    resetChannelListButton:SetPoint("TOP", x, y - (soundfileDamageFrameHeight - resetSoundfileButtonHeight) / 2)
    resetChannelListButton:SetSize(resetSoundfileButtonWidth, resetSoundfileButtonHeight)
    resetChannelListButton:SetText("Reset")
    resetChannelListButton:SetScript("OnClick", function(...)
        SBM_soundfileDamage = "Interface\\AddOns\\yaba\\bam.ogg"
        soundfileDamageFrame:SetText(SBM_soundfileDamage)
    end)
end

function SBM:createResetSoundfileHealButton(parentFrame, resetSoundfileButtonWidth, x, y, soundfileDamageFrameHeight)
    local resetSoundfileButtonHeight = 24
    resetChannelListButton = CreateFrame("Button", "ResetSoundfileHeal", parentFrame, "UIPanelButtonTemplate");
    resetChannelListButton:ClearAllPoints()
    resetChannelListButton:SetPoint("TOP", x, y - (soundfileDamageFrameHeight - resetSoundfileButtonHeight) / 2)
    resetChannelListButton:SetSize(resetSoundfileButtonWidth, resetSoundfileButtonHeight)
    resetChannelListButton:SetText("Reset")
    resetChannelListButton:SetScript("OnClick", function(...)
        SBM_soundfileHeal = "Interface\\AddOns\\yaba\\bam.ogg"
        soundfileHealFrame:SetText(SBM_soundfileHeal)
    end)
end

function SBM:createResetChannelListButton(parentFrame, channelList, channelButtonList)
    resetChannelListButton = CreateFrame("Button", "ResetButtonChannels", parentFrame, "UIPanelButtonTemplate");
    resetChannelListButton:ClearAllPoints()
    resetChannelListButton:SetPoint("TOPLEFT", 32, ((#channelList) + 1) * -24 - 8)
    resetChannelListButtonText = "Clear Channel List (May fix bugs after updating)"
    resetChannelListButton:SetSize(resetChannelListButtonText:len() * 7, 32)
    resetChannelListButton:SetText(resetChannelListButtonText)
    resetChannelListButton:SetScript("OnClick", function(...)
        for i = 1, #channelButtonList do
            channelButtonList[i]:SetChecked(false)
        end
        SBM_outputChannelList = {}
    end)
end

function SBM:createColorSlider(i, panel, rgb, yOffSet)
    local slider = CreateFrame("Slider", "SBM_Slider" .. i, panel, "OptionsSliderTemplate")
    slider:ClearAllPoints()
    slider:SetPoint("TOPLEFT", 32, -16 * 2 * (i - 1) + yOffSet)
    slider:SetSize(256, 16)
    slider:SetMinMaxValues(0, 255)
    slider:SetValueStep(1)
    _G[slider:GetName() .. "Low"]:SetText("|c00ffcc00Min:|r 0")
    _G[slider:GetName() .. "High"]:SetText("|c00ffcc00Max:|r 255")
    slider:SetScript("OnValueChanged", function()
        local value = floor(slider:GetValue())
        _G[slider:GetName() .. "Text"]:SetText("|c00ffcc00" .. rgb[i].color .. "|r " .. value)
        _G[slider:GetName() .. "Text"]:SetFont(GameFontNormal:GetFont(), 14, "NONE")
        rgb[i].value = SBM:convertRGBDecimalToRGBHex(value)
        SBM_color = "|cff" .. rgb[1].value .. rgb[2].value .. rgb[3].value
        SBM:setPanelTexts()
    end)
    slider:SetValue(tonumber("0x" .. rgb[i].value))

end

function SBM:saveWhisperList()
    SBM_whisperList = {}
    for arg in string.gmatch(whisperFrame:GetText(), "%S+") do
        table.insert(SBM_whisperList, arg)
    end
end

function SBM:saveSoundfileDamage()
    SBM_soundfileDamage = soundfileDamageFrame:GetText()
end

function SBM:saveSoundfileHeal()
    SBM_soundfileHeal = soundfileHealFrame:GetText()
end

function SBM:saveDamageOutputList()
    SBM_outputDamageMessage = outputDamageMessageEditBox:GetText()
end

function SBM:saveHealOutputList()
    SBM_outputHealMessage = outputHealMessageEditBox:GetText()
end

function SBM:saveThreshold()
    SBM_threshold = thresholdEditBox:GetNumber()
end

function SBM:createEditBox(name, parentFrame, height, width)
    local eb = CreateFrame("EditBox", name, parentFrame, "InputBoxTemplate")
    eb:ClearAllPoints()
    eb:SetAutoFocus(false)
    eb:SetHeight(height)
    eb:SetWidth(width)
    eb:SetFontObject("ChatFontNormal")
    return eb
end

function SBM:convertRGBDecimalToRGBHex(decimal)
    local result
    local numbers = "0123456789ABCDEF"
    result = numbers:sub(1 + (decimal / 16), 1 + (decimal / 16)) .. numbers:sub(1 + (decimal % 16), 1 + (decimal % 16))
    return result
end

function SBM:createMinimapButton()

    --Dropdown Menu
    local lib = LibStub("LibDropDownMenu");
    local menuFrame = lib.Create_DropDownMenu("MyAddOn_DropDownMenu");
    -- instead of template UIDropDownMenuTemplate
    local menuList = {
        { text = "Crit List options", isNotRadio = true, notCheckable = true, hasArrow = true,
          menuList = {
              { text = "List crits", isNotRadio = true, notCheckable = true,
                func = function()
                    SBM:listCrits();
                end
              },

              { text = "Report crits", isNotRadio = true, notCheckable = true,
                func = function()
                    SBM:reportCrits();
                end
              },

              { text = "Clear crits", isNotRadio = true, notCheckable = true,
                func = function()
                    SBM:clearCritList();
                end
              },
          }
        },

        { text = "Open config", isNotRadio = true, notCheckable = true,
          func = function()
              InterfaceOptionsFrame_OpenToCategory(yabaConfig.panel)
              InterfaceOptionsFrame_OpenToCategory(yabaConfig.panel)
          end
        },
        { text = "Close menu", isNotRadio = true, notCheckable = true },
    };

    --Minimap Icon
    SBM_icon = SBM_ldb:NewDataObject("SBM_dataObject", {
        type = "data source",
        label = "SBM_MinimapButton",
        text = "SBM Minimap Icon",
        icon = "Interface\\AddOns\\yaba\\textures\\Bam_Icon",
        OnClick = function(_, button)
            if button == "LeftButton" or button == "RightButton" then
                lib.EasyMenu(menuList, menuFrame, "LibDBIcon10_SBM_dataObject", 0, 0, "MENU");
            end
        end,
    })
    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("SBM_dataObject", SBM_icon, SBM_MinimapSettings)
end

function SBM:setPanelTexts()
    GeneralOptionsDescription:SetText(SBM_color .. "Choose sub menu to change options.\n\n\nCommand line options:\n\n"
            .. "/bam list: lists highest crits of each spell.\n"
            .. "/bam report: report highest crits of each spell to channel list.\n"
            .. "/bam clear: delete list of highest crits.\n/bam config: Opens this config page.")
    OutputDamageMessageDescription:SetText(SBM_color .. "Output Message Damage")
    OutputHealMessageDescription:SetText(SBM_color .. "Output Message Heal")
    EventTypeDescription:SetText(SBM_color .. "Event Types to Trigger")
    yabaGeneralOptions.panel.title:SetText(SBM_color .. "Change color of Font")
    FontColorDescription:SetText(SBM_color .. "Change color of Font")
    OutputChannelDescription:SetText(SBM_color .. "Output Channel")
    ThresholdDescription:SetText(SBM_color .. "Least amount of damage/heal to trigger bam:")
    OnlyOnMaxCritsDescription:SetText(SBM_color .. "Trigger options:")
    OtherOptionsDescription:SetText(SBM_color .. "Other options:")
end

local VorpCore = exports.vorp_core:GetCore()
local Menu = exports.vorp_menu:GetMenuData()

local prompts = GetRandomIntInRange(0, 0xffffff)
local startPrompt
local Menu = exports.vorp_menu:GetMenuData()

local currentGoldPrice = Config.GoldBarPrice
local currentSilverPrice = Config.SilverBarPrice

RegisterNetEvent("menu:updateSilverPrice")
AddEventHandler("menu:updateSilverPrice", function(newPriceSilver)
    currentSilverPrice = newPriceSilver
end)

RegisterNetEvent("menu:updateGoldPrice")
AddEventHandler("menu:updateGoldPrice", function(newPrice)
    currentGoldPrice = newPrice
end)

Citizen.CreateThread(function()
    local str = Config.PromptTextTitle
    startPrompt = PromptRegisterBegin()
    PromptSetControlAction(startPrompt, Config.PromptKey)
    str = CreateVarString(10, 'LITERAL_STRING', str)
    PromptSetText(startPrompt, str)
    PromptSetEnabled(startPrompt, true)
    PromptSetVisible(startPrompt, true)
    PromptSetStandardMode(startPrompt, true)
    PromptSetGroup(startPrompt, prompts)
    PromptRegisterEnd(startPrompt)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - Config.TradeLocation)
        local currentHour = GetClockHours()

        if distance <= Config.PromptRadius then
            local label
            if currentHour >= Config.MarketOpenHour and currentHour < Config.MarketCloseHour then
                label = CreateVarString(10, 'LITERAL_STRING', Config.PromptTextDescr1 .. " " .. string.format("%02d", Config.MarketOpenHour) .. " " .. Config.PromptTextDescr2 .. " " .. string.format("%02d", Config.MarketCloseHour))
            else
                label = CreateVarString(10, 'LITERAL_STRING', Config.PromptTextDescr3 .. " " .. string.format("%02d", Config.MarketOpenHour))
            end

            PromptSetActiveGroupThisFrame(prompts, label)

            if Citizen.InvokeNative(0xC92AC953F0A982AE, startPrompt) then
                if currentHour >= Config.MarketOpenHour and currentHour < Config.MarketCloseHour then
                    OpenCustomMenu()
                else
                    TriggerEvent("vorp:TipBottom", Config.Notifications.ClosedTrade, 5000)
                end
            end
        end
    end
end)

RegisterNetEvent("menu:receiveLastUpdate")
AddEventHandler("menu:receiveLastUpdate", function(serverTime)
    lastUpdateTime = serverTime
end)

function calculateRemainingTime()
    local currentTime = os.time()
    local elapsedTime = currentTime - lastUpdateTime
    return math.max(0, timerInterval - elapsedTime)
end

Citizen.CreateThread(function()
    TriggerServerEvent("menu:syncLastUpdate")
end)

RegisterNetEvent("menu:updateGoldPrice")
AddEventHandler("menu:updateGoldPrice", function(newPrice)
    currentGoldPrice = newPrice
end)

RegisterNetEvent("menu:updateSilverPrice")
AddEventHandler("menu:updateSilverPrice", function(newPriceSilver)
    currentSilverPrice = newPriceSilver
end)

function IsMarketOpen()
    local hour = GetClockHours()
    return hour >= Config.MarketOpenHour and hour < Config.MarketCloseHour
end

local isMenuOpen = false

function OpenCustomMenu()
    if not IsMarketOpen() then
        local message = string.format(Config.Notifications.ClosedTradeAndOpen .. " " .. "%02d:00 - %02d:00.", Config.MarketOpenHour, Config.MarketCloseHour)
        TriggerEvent("vorp:TipRight", message, 5000)
        return
    end

    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    TaskStandStill(playerPed, -1)
    FreezeEntityPosition(playerPed, true)
    isMenuOpen = true

    TriggerServerEvent("menu:requestGoldPrice")
    TriggerServerEvent("menu:requestSilverPrice")

    TriggerServerEvent("menu:requestGoldAndSilverBarLimitAndTimer")

    RegisterNetEvent("menu:updateMenuWithTimer")
    AddEventHandler("menu:updateMenuWithTimer", function(goldBuyRemaining, goldSellRemaining, silverBuyRemaining, silverSellRemaining, remainingTime)
    if not goldBuyRemaining or not goldSellRemaining or not silverBuyRemaining or not silverSellRemaining then
        return
    end

    local hours = math.floor(remainingTime / 3600)
    local minutes = math.floor((remainingTime % 3600) / 60)
    local seconds = remainingTime % 60
    local timeString = string.format("%02d:%02d:%02d", hours, minutes, seconds)

    local formattedGoldPrice = string.format("%.2f", currentGoldPrice or 0)
    local formattedSilverPrice = string.format("%.2f", currentSilverPrice or 0)

    local goldBuyPrice = currentGoldPrice + (currentGoldPrice * Config.BankTaxPercentage / 100)
    local silverBuyPrice = currentSilverPrice + (currentSilverPrice * Config.BankTaxPercentage / 100)

    local goldImage = string.format("nui://vorp_inventory/html/img/items/%s.png", Config.GoldbarItemName)
    local silverImage = string.format("nui://vorp_inventory/html/img/items/%s.png", Config.SilverbarItemName)
 
     local MenuElements = {
         {
             label = (Config.MenuElements.BuyIngots .. " " .. Config.MenuElements.Gold .. " " .. "<span style='color:green;'>$%.2f</span>"):format(goldBuyPrice),
             value = "buy_goldbar",
             desc = (Config.MenuElements.RemainingIngots .. " (Max: %d)" .. " | " .. Config.MenuElements.ChangePrice .. " %s | +%d%% " .. Config.MenuElements.BankTaxes .. " " .. "<br><img style='max-height:64px;max-width:64px;' src='%s'>")
                 :format(goldBuyRemaining or 0, timeString, Config.BankTaxPercentage, goldImage),
         },
         {
             label = (Config.MenuElements.SellIngots .. " " .. Config.MenuElements.Gold .. " " .. "<span style='color:green;'>$%.2f</span>"):format(currentGoldPrice),
             value = "sell_goldbar",
             desc = (Config.MenuElements.SellableIngots .. " " .. "(Max: %d)" .. " | " .. Config.MenuElements.ChangePrice .. " %s<br><img style='max-height:64px;max-width:64px;' src='%s'>")
                 :format(goldSellRemaining or 0, timeString, goldImage),
         },
         {
             label = (Config.MenuElements.BuyIngots .. " " .. Config.MenuElements.Silver .. " " .. "<span style='color:green;'>$%.2f</span>"):format(silverBuyPrice),
             value = "buy_silverbar",
             desc = (Config.MenuElements.RemainingIngots .. " " .. " (Max: %d)" .. " | " .. Config.MenuElements.ChangePrice .. " %s | +%d%% " .. Config.MenuElements.BankTaxes .. " " .. "<br><img style='max-height:64px;max-width:64px;' src='%s'>")
                 :format(silverBuyRemaining or 0, timeString, Config.BankTaxPercentage, silverImage),
         },
         {
             label = (Config.MenuElements.SellIngots .. " " .. Config.MenuElements.Silver .. " " .. "<span style='color:green;'>$%.2f</span>"):format(currentSilverPrice),
             value = "sell_silverbar",
             desc = (Config.MenuElements.SellableIngots .. " " .. "(Max: %d)" .. " | " .. Config.MenuElements.ChangePrice .. " %s<br><img style='max-height:64px;max-width:64px;' src='%s'>")
                 :format(silverSellRemaining or 0, timeString, silverImage),
         },
         {
             label = Config.MenuElements.GraphTitle,
             value = "open_graphic",
             desc = Config.MenuElements.GraphDesc,
         },
         {
             label = Config.MenuElements.CloseTitle,
             value = "close",
             desc = Config.MenuElements.CloseDesc,
         }
     }
 
     Menu.Open(
         "default", GetCurrentResourceName(), "custom_menu",
         {
             title = Config.MenuElements.MenuTitle,
             subtext = Config.MenuElements.MenuSubText,
             align = Config.MenuAlign,
             elements = MenuElements,
         },
         function(data, menu)
             if data.current.value == "buy_goldbar" then
                 HandleBuyGold(goldBuyRemaining, goldBuyPrice)
                 CloseMenu(playerPed, menu)
             elseif data.current.value == "sell_goldbar" then
                 HandleSellGold(goldSellRemaining)
                 CloseMenu(playerPed, menu)
             elseif data.current.value == "buy_silverbar" then
                 HandleBuySilver(silverBuyRemaining, silverBuyPrice)
                 CloseMenu(playerPed, menu)
             elseif data.current.value == "sell_silverbar" then
                 HandleSellSilver(silverSellRemaining)
                 CloseMenu(playerPed, menu)
             elseif data.current.value == "open_graphic" then
                 TriggerServerEvent("vlab-goldandsilverprice:fetchHistory")
                 CloseMenu(playerPed, menu)
             elseif data.current.value == "close" then
                 CloseMenu(playerPed, menu)
             end
         end,
         function(data, menu)
             CloseMenu(playerPed, menu)
         end
     )
    end)
end

function HandleBuyGold(buyRemaining)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)

    local input = {
        type = "enableinput",
        inputType = "input",
        button = Config.Inputs.Confirm,
        placeholder = Config.Inputs.EnterAmount,
        style = "block",
        attributes = {
            inputHeader = Config.MenuElements.BuyIngots .. " " .. Config.MenuElements.Gold,
            type = "number",
            pattern = "[0-9]+",
            title = Config.Inputs.OnlyNumber
        }
    }

    local result = exports.vorp_inputs:advancedInput(input)
    if result then
        local quantity = tonumber(result)
        if not quantity or not buyRemaining then
            TriggerEvent("vorp:TipRight", Config.Notifications.BuyError, 5000)
            return
        end

        if quantity > 0 and quantity <= buyRemaining then
            local cost = currentGoldPrice * quantity
            TriggerServerEvent("menu:purchaseGoldBars", quantity, currentGoldPrice)
        else
            TriggerEvent("vorp:TipRight", Config.Notifications.InvalidBuyError, 5000)
        end
    else
    end
end

function HandleSellGold(sellRemaining)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)

    local input = {
        type = "enableinput",
        inputType = "input",
        button = Config.Inputs.Confirm,
        placeholder = Config.Inputs.EnterAmount,
        style = "block",
        attributes = {
            inputHeader = Config.MenuElements.SellIngots .. " " .. Config.MenuElements.Gold,
            type = "number",
            pattern = "[0-9]+",
            title = Config.Inputs.OnlyNumber
        }
    }

    local result = exports.vorp_inputs:advancedInput(input)
    if result then
        local quantity = tonumber(result)
        if not quantity or not sellRemaining then
            TriggerEvent("vorp:TipRight", Config.Notifications.SellError, 5000)
            return
        end

        if quantity > 0 and quantity <= sellRemaining then
            local profit = currentGoldPrice * quantity
            TriggerServerEvent("goldbar:sell", quantity, currentGoldPrice)
            TriggerServerEvent("menu:requestGoldBarLimitAndTimer")
        else
            TriggerEvent("vorp:TipRight", Config.Notifications.InvalidAmount, 5000)
        end
    else
    end
end

function HandleBuySilver(buyRemaining)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)

    local input = {
        type = "enableinput",
        inputType = "input",
        button = Config.Inputs.Confirm,
        placeholder = Config.Inputs.EnterAmount,
        style = "block",
        attributes = {
            inputHeader = Config.MenuElements.BuyIngots .. " " .. Config.MenuElements.Silver,
            type = "number",
            pattern = "[0-9]+",
            title = Config.Inputs.OnlyNumber
        }
    }

    local result = exports.vorp_inputs:advancedInput(input)
    if result then
        local quantity = tonumber(result)
        if quantity and quantity > 0 and quantity <= (buyRemaining or 0) then
            local cost = currentSilverPrice * quantity
            TriggerServerEvent("menu:purchaseSilverBars", quantity, currentSilverPrice)
            TriggerServerEvent("menu:requestSilverBarLimitAndTimer")
        else
            TriggerEvent("vorp:TipRight", Config.Notifications.InvalidBuyError, 5000)
        end
    else
    end
end

function HandleSellSilver(sellRemaining)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)

    local input = {
        type = "enableinput",
        inputType = "input",
        button = Config.Inputs.Confirm,
        placeholder = Config.Inputs.EnterAmount,
        style = "block",
        attributes = {
            inputHeader = Config.MenuElements.SellIngots .. " " .. Config.MenuElements.Silver,
            type = "number",
            pattern = "[0-9]+",
            title = Config.Inputs.OnlyNumber
        }
    }

    local result = exports.vorp_inputs:advancedInput(input)
    if result then
        local quantity = tonumber(result)
        if quantity and quantity > 0 and quantity <= (sellRemaining or 0) then
            local profit = currentSilverPrice * quantity
            TriggerServerEvent("silverbar:sell", quantity, currentSilverPrice)
            TriggerServerEvent("menu:requestSilverBarLimitAndTimer")
        else
            TriggerEvent("vorp:TipRight", Config.Notifications.InvalidAmount, 5000)
        end
    else
    end
end

function CloseMenu(playerPed, menu)
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
    menu.close()
end

RegisterNetEvent("silverprice:sendHistory")
AddEventHandler("silverprice:sendHistory", function(history)
    SendNUIMessage({
        type = "openSilverPriceHistory",
        history = history,
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent("receiveSilverPriceHistory")
AddEventHandler("receiveSilverPriceHistory", function(history)
    SendNUIMessage({
        type = "openSilverPriceHistory",
        history = history
    })
end)

RegisterNetEvent("goldprice:sendHistory")
AddEventHandler("goldprice:sendHistory", function(history)
    SendNUIMessage({
        type = "openGoldPriceHistory",
        history = history,
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback("closeNUI", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNetEvent("goldandsilverprice:sendHistory")
AddEventHandler("goldandsilverprice:sendHistory", function(data)
    SendNUIMessage({
        type = "openGoldAndSilverPriceHistory",
        goldHistory = data.gold,
        silverHistory = data.silver,
    })
    SetNuiFocus(true, true)
end)

function sendCustomNotification(message, type)
    local notifType = type or "info"
    SendNUIMessage({
        type = "notification",
        message = message,
        notifType = notifType,
    })
end

RegisterNetEvent("menu:updateSilverPrice")
AddEventHandler("menu:updateSilverPrice", function(newPriceSilver)
    currentSilverPrice = newPriceSilver
    sendCustomNotification(Config.Notifications.NewPriceIngots .. " $" .. newPriceSilver, "success")
end)

Citizen.CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/'.. Config.CommandChangePrices, Config.Suggestions.ChangePrices,{})
end)
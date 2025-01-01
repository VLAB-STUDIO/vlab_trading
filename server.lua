local VorpCore = {}
TriggerEvent("getCore", function(core)
    VorpCore = core
end)

local goldBarsSold = 0
local goldBarsSoldLimit = 0
local silverBarsSold = 0
local silverBarsSoldLimit = 0

local currentGoldPrice = Config.GoldBarPrice
local currentSilverPrice = Config.SilverBarPrice

local lastUpdateTime = 0
local timerInterval = Config.TimerInterval or 7200
local lastGoldPriceUpdate = os.time()
local lastSilverPriceUpdate = os.time()

local function fetchGoldPrice()
    exports.oxmysql:scalar("SELECT price FROM gold_prices LIMIT 1", {}, function(result)
        if result then
            currentGoldPrice = tonumber(result)
        else
            -- print("[DEBUG] Nessun prezzo trovato nella tabella gold_prices.")
        end
    end)
end

local function fetchSilverPrice()
    exports.oxmysql:scalar("SELECT price FROM silver_prices LIMIT 1", {}, function(result)
        if result then
            currentSilverPrice = tonumber(result)
        else
            -- print("[DEBUG] Nessun prezzo trovato nella tabella silver_prices.")
        end
    end)
end

RegisterNetEvent("menu:syncLastUpdate")
AddEventHandler("menu:syncLastUpdate", function()
    local _source = source
    if not lastGoldPriceUpdate then
        lastGoldPriceUpdate = os.time()
    end
    if not lastSilverPriceUpdate then
        lastSilverPriceUpdate = os.time()
    end
    TriggerClientEvent("menu:receiveLastUpdate", _source, lastGoldPriceUpdate)
    TriggerClientEvent("menu:receiveLastUpdate", _source, lastSilverPriceUpdate)
end)

RegisterNetEvent("menu:requestGoldAndSilverBarLimitAndTimer")
AddEventHandler("menu:requestGoldAndSilverBarLimitAndTimer", function()
    local src = source
    local goldBuyRemaining = Config.GlobalMaxGoldBars - goldBarsSold
    local goldSellRemaining = Config.GlobalMaxGoldBars - goldBarsSoldLimit
    local silverBuyRemaining = Config.GlobalMaxSilverBars - silverBarsSold
    local silverSellRemaining = Config.GlobalMaxSilverBars - silverBarsSoldLimit
    local currentTime = os.time()
    local elapsedTime = currentTime - math.max(lastGoldPriceUpdate, lastSilverPriceUpdate)
    local remainingTime = math.max(0, Config.TimerInterval - elapsedTime)
    TriggerClientEvent("menu:updateMenuWithTimer", src, goldBuyRemaining, goldSellRemaining, silverBuyRemaining, silverSellRemaining, remainingTime)
end)

RegisterCommand(Config.CommandChangePrices, function(source, args, rawCommand)
    local src = source
    local playerIdentifier = GetPlayerIdentifier(src, 0)
    if not isAuthorized(playerIdentifier) then
        TriggerClientEvent("vorp:TipBottom", src, Config.Notifications.NoCommandAuthorization, 5000)
        -- print(string.format("[DEBUG] Utente non autorizzato ha tentato di utilizzare /%s: %s", Config.CommandChangePrices, playerIdentifier))
        return
    end
    UpdateGoldPrice()
    UpdateSilverPrice()
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.TimerInterval * 1000)
        UpdateGoldPrice()
        UpdateSilverPrice()
    end
end)

function UpdateGoldPrice()
    local range = Config.GoldPriceChangeRange
    local percentageChange = math.random() * (range.max - range.min) + range.min
    local isIncrease = math.random(0, 1) == 1
    local priceChange = currentGoldPrice * percentageChange

    if not isIncrease then
        priceChange = -priceChange
    end

    local newPrice = math.max(0.01, currentGoldPrice + priceChange)

    exports.oxmysql:execute("UPDATE gold_prices SET price = ?", {newPrice}, function(result)
        if result and result.affectedRows > 0 then
            currentGoldPrice = newPrice
            lastGoldPriceUpdate = os.time()
            exports.oxmysql:insert("INSERT INTO gold_price_history (price) VALUES (?)", {newPrice}, function(insertResult)
                if insertResult and insertResult > 0 then
                else
                    -- print("[DEBUG] Errore nel salvataggio del prezzo dell'oro nello storico.")
                end
            end)
            TriggerClientEvent("menu:updateGoldPrice", -1, currentGoldPrice)
        else
            -- print("[DEBUG] Errore nell'aggiornamento del prezzo dell'oro.")
        end
    end)
end

function UpdateSilverPrice()
    local range = Config.SilverPriceChangeRange
    local percentageChange = math.random() * (range.max - range.min) + range.min
    local isIncrease = math.random(0, 1) == 1
    local priceChange = currentSilverPrice * percentageChange

    if not isIncrease then
        priceChange = -priceChange
    end

    local newPrice = math.max(0.01, currentSilverPrice + priceChange)

    exports.oxmysql:execute("UPDATE silver_prices SET price = ?", {newPrice}, function(result)
        if result and result.affectedRows > 0 then
            currentSilverPrice = newPrice
            lastSilverPriceUpdate = os.time()
            exports.oxmysql:insert("INSERT INTO silver_price_history (price) VALUES (?)", {newPrice}, function(insertResult)
                if insertResult and insertResult > 0 then
                    -- print("[DEBUG] Prezzo dell'argento salvato nello storico.")
                else
                    -- print("[DEBUG] Errore nel salvataggio del prezzo dell'argento nello storico.")
                end
            end)
            TriggerClientEvent("menu:updateSilverPrice", -1, currentSilverPrice)
        else
            -- print("[DEBUG] Errore nell'aggiornamento del prezzo dell'argento.")
        end
    end)
end

function isAuthorized(steamHex)
    for _, authorizedHex in ipairs(Config.AuthorizedSteamHex) do
        if steamHex == authorizedHex then
            return true
        end
    end
    return false
end

Citizen.CreateThread(function()
    fetchGoldPrice()
    fetchSilverPrice()
    while true do
        Citizen.Wait(2 * 60 * 60 * 1000)
        updateGoldPrice()
        updateSilverPrice()
    end
end)

RegisterNetEvent("menu:requestGoldPrice")
AddEventHandler("menu:requestGoldPrice", function()
    local _source = source
    TriggerClientEvent("menu:updateGoldPrice", _source, currentGoldPrice)
end)

RegisterNetEvent("menu:requestSilverPrice")
AddEventHandler("menu:requestSilverPrice", function()
    local _source = source
    TriggerClientEvent("menu:updateSilverPrice", _source, currentSilverPrice)
end)

RegisterNetEvent("menu:purchaseGoldBars")
AddEventHandler("menu:purchaseGoldBars", function(quantity, marketPrice)
    local _source = source
    local user = VorpCore.getUser(_source)
    if not user then
        -- print("[DEBUG SERVER] Errore: utente non trovato.")
        return
    end
    local character = user.getUsedCharacter
    if not character then
        -- print("[DEBUG SERVER] Errore: personaggio non trovato.")
        return
    end

    local taxPercentage = Config.BankTaxPercentage / 100
    local priceWithTax = marketPrice + (marketPrice * taxPercentage)
    local totalCost = priceWithTax * quantity

    if character.money >= totalCost then
        exports.vorp_inventory:canCarryItem(_source, Config.GoldbarItemName, quantity, function(canCarry)
            if canCarry then
                character.removeCurrency(0, totalCost)
                exports.vorp_inventory:addItem(_source, Config.GoldbarItemName, quantity, nil, function(success)
                    if success then
                        -- print("[DEBUG SERVER] Lingotti d'oro acquistati con successo.")
                        goldBarsSold = goldBarsSold + quantity
                        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.YouHavePurchased .. " " .. quantity .. " " .. Config.Notifications.Ingots .. " " .. Config.MenuElements.Gold, 5000)
                    else
                        -- print("[DEBUG SERVER] Errore durante l'aggiunta dei lingotti d'oro all'inventario.")
                        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.BuyError, 5000)
                    end
                end)
            else
                -- print("[DEBUG SERVER] L'inventario del giocatore non può trasportare i lingotti d'oro.")
                TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.CantCarryAnyMore, 5000)
            end
        end)
    else
        -- print("[DEBUG SERVER] Fondi insufficienti per completare l'acquisto.")
        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.InsufficientFunds, 5000)
    end
end)

RegisterNetEvent("menu:purchaseSilverBars")
AddEventHandler("menu:purchaseSilverBars", function(quantity, marketPrice)
    local _source = source
    local user = VorpCore.getUser(_source)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end
    local taxPercentage = Config.BankTaxPercentage / 100
    local priceWithTax = marketPrice + (marketPrice * taxPercentage)
    local totalCost = priceWithTax * quantity
    if not silverBarsSold then
        silverBarsSold = 0
    end
    if not Config.GlobalMaxSilverBars then
        return
    end
    if silverBarsSold + quantity > Config.GlobalMaxSilverBars then
        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.GlobalLimitReached, 5000)
        return
    end
    if character.money >= totalCost then
        exports.vorp_inventory:canCarryItem(_source, Config.SilverbarItemName, quantity, function(canCarry)
            if canCarry then
                character.removeCurrency(0, totalCost)
                exports.vorp_inventory:addItem(_source, Config.SilverbarItemName, quantity, nil, function(success)
                    if success then
                        silverBarsSold = silverBarsSold + quantity
                        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.YouHavePurchased .. " " .. quantity .. " " .. Config.Notifications.Ingots .. " " .. Config.MenuElements.Silver, 5000)
                    else
                        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.BuyError, 5000)
                    end
                end)
            else
                TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.CantCarryAnyMore, 5000)
            end
        end)
    else
        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.InsufficientFunds, 5000)
    end
end)

RegisterNetEvent("goldbar:sell")
AddEventHandler("goldbar:sell", function(quantity, marketPrice)
    local _source = source
    local user = VorpCore.getUser(_source)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end
    if goldBarsSoldLimit + quantity > Config.GlobalMaxGoldBars then
        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.GlobalLimitReached, 5000)
        return
    end
    local totalPrice = marketPrice * quantity
    exports.vorp_inventory:subItem(_source, Config.GoldbarItemName, quantity, nil, function(success)
        if success then
            goldBarsSoldLimit = goldBarsSoldLimit + quantity -- Incrementa il contatore globale
            character.addCurrency(0, totalPrice)
            TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.YouSold .. " " .. quantity .. Config.Notifications.GoldIngot .. " " .. Config.Notifications.For .. " $" .. totalPrice, 5000)
        else
            TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.SellError, 5000)
        end
    end)
end)

RegisterNetEvent("silverbar:sell")
AddEventHandler("silverbar:sell", function(quantity, marketPrice)
    local _source = source
    local user = VorpCore.getUser(_source)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end
    if silverBarsSoldLimit + quantity > Config.GlobalMaxSilverBars then
        TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.SaleGlobalLimitReached, 5000)
        return
    end
    local totalPrice = marketPrice * quantity
    exports.vorp_inventory:subItem(_source, Config.SilverbarItemName, quantity, nil, function(success)
        if success then
            silverBarsSoldLimit = silverBarsSoldLimit + quantity
            character.addCurrency(0, totalPrice)
            TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.YouSold .. " " .. quantity .. " " .. Config.Notifications.SilverIngot .. " " ..Config.Notifications.For .. " $" .. totalPrice, 5000)
        else
            TriggerClientEvent("vorp:TipRight", _source, Config.Notifications.SellError, 5000)
        end
    end)
end)

RegisterNetEvent("menu:requestGoldBarLimit")
AddEventHandler("menu:requestGoldBarLimit", function()
    local _source = source
    local buyRemaining = Config.GlobalMaxGoldBars - goldBarsSold
    local sellRemaining = Config.GlobalMaxGoldBars - goldBarsSoldLimit
    TriggerClientEvent("menu:updateMenu", _source, buyRemaining, sellRemaining)
end)

RegisterNetEvent("menu:requestSilverBarLimit")
AddEventHandler("menu:requestSilverBarLimit", function()
    local _source = source
    local buyRemaining = Config.GlobalMaxSilverBars - silverBarsSold
    local sellRemaining = Config.GlobalMaxSilverBars - silverBarsSoldLimit
    TriggerClientEvent("menu:updateMenu", _source, buyRemaining, sellRemaining)
end)

RegisterNetEvent("goldprice:fetchPriceInfo")
AddEventHandler("goldprice:fetchPriceInfo", function()
    local src = source
    exports.oxmysql:execute("SELECT MIN(CAST(price AS DECIMAL(10,2))) AS minPrice, MAX(CAST(price AS DECIMAL(10,2))) AS maxPrice FROM gold_price_history", {}, function(results)
        if results and #results > 0 then
            local minPrice = tonumber(results[1].minPrice) or 0
            local maxPrice = tonumber(results[1].maxPrice) or 0
            TriggerClientEvent("goldprice:sendPriceInfo", src, minPrice, maxPrice)
        else
            -- print("[DEBUG] Nessun risultato trovato per il prezzo minimo e massimo.")
            TriggerClientEvent("goldprice:sendPriceInfo", src, 0, 0)
        end
    end)
end)

RegisterNetEvent("silverprice:fetchPriceInfo")
AddEventHandler("silverprice:fetchPriceInfo", function()
    local src = source
    exports.oxmysql:execute("SELECT MIN(CAST(price AS DECIMAL(10,2))) AS minPrice, MAX(CAST(price AS DECIMAL(10,2))) AS maxPrice FROM silver_price_history", {}, function(results)
        if results and #results > 0 then
            local minPrice = tonumber(results[1].minPrice) or 0
            local maxPrice = tonumber(results[1].maxPrice) or 0
            TriggerClientEvent("silverprice:sendPriceInfo", src, minPrice, maxPrice)
        else
            -- print("[DEBUG] Nessun risultato trovato per il prezzo minimo e massimo.")
            TriggerClientEvent("silverprice:sendPriceInfo", src, 0, 0)
        end
    end)
end)

RegisterNetEvent("getSilverPriceHistory")
AddEventHandler("getSilverPriceHistory", function()
    local source = source
    MySQL.Async.fetchAll("SELECT * FROM silver_price_history ORDER BY timestamp ASC", {}, function(result)
        TriggerClientEvent("receiveSilverPriceHistory", source, result)
    end)
end)

RegisterNetEvent("goldprice:fetchHistory")
AddEventHandler("goldprice:fetchHistory", function()
    local src = source
    exports.oxmysql:execute(
        "SELECT price, DATE_FORMAT(timestamp, '%Y-%m-%d %H:%i:%s') as timestamp FROM gold_price_history ORDER BY timestamp ASC",
        {},
        function(results)
            if results then
                TriggerClientEvent("goldprice:sendHistory", src, results)
            else
                TriggerClientEvent("goldprice:sendHistory", src, {})
            end
        end
    )
end)

RegisterNetEvent("vlab-goldandsilverprice:fetchHistory")
AddEventHandler("vlab-goldandsilverprice:fetchHistory", function()
    local src = source
    exports.oxmysql:execute(
        "SELECT price, DATE_FORMAT(timestamp, '%Y-%m-%d %H:%i:%s') as timestamp FROM gold_price_history ORDER BY timestamp ASC",
        {},
        function(goldResults)
            if not goldResults then
                goldResults = {}
            end
            exports.oxmysql:execute(
                "SELECT price, DATE_FORMAT(timestamp, '%Y-%m-%d %H:%i:%s') as timestamp FROM silver_price_history ORDER BY timestamp ASC",
                {},
                function(silverResults)
                    if not silverResults then
                        silverResults = {}
                    end
                    TriggerClientEvent("goldandsilverprice:sendHistory", src, {
                        gold = goldResults,
                        silver = silverResults
                    })
                    -- print("[DEBUG] Storico dei prezzi inviato al client.")
                end
            )
        end
    )
end)

RegisterCommand(Config.CommandChangePrices, function(source, args, rawCommand)
    local src = source
    local playerIdentifier = GetPlayerIdentifier(src, 0)
    if not isAuthorized(playerIdentifier) then
        TriggerClientEvent("vorp:TipBottom", src, Config.Notifications.NoCommandAuthorization, 5000)
        return
    end
    local function updateMetalPrice(metal, currentPrice, priceTable, historyTable, updateEvent)
        local percentageChange = math.random(1, 10) / (metal == "gold" and 500 or 1000)
        local isIncrease = math.random(0, 1) == 1
        local priceChange = currentPrice * percentageChange
        if not isIncrease then
            priceChange = -priceChange
        end
        local newPrice = math.max(0.01, currentPrice + priceChange)
        exports.oxmysql:execute("UPDATE " .. priceTable .. " SET price = ?", {newPrice}, function(result)
            if result and result.affectedRows > 0 then
                if metal == "gold" then
                    currentGoldPrice = newPrice
                else
                    currentSilverPrice = newPrice
                end
                exports.oxmysql:insert("INSERT INTO " .. historyTable .. " (price) VALUES (?)", {newPrice}, function(insertResult)
                    if insertResult and insertResult > 0 then
                    else
                        -- print(string.format("[DEBUG] Errore nel salvataggio della variazione del prezzo di %s nello storico.", metal))
                    end
                end)
                TriggerClientEvent(updateEvent, -1, newPrice)
                TriggerClientEvent("vorp:TipRight", src, string.format(Config.Notifications.PriceIngots .. " %s" .. " " .. Config.Notifications.Updated .. " $%.2f", metal, newPrice), 5000)
            else
                TriggerClientEvent("vorp:TipBottom", src, string.format("Errore durante l'aggiornamento del prezzo dei lingotti di %s. Riprova più tardi.", metal), 5000)
            end
        end)
    end

    -- Aggiorna i prezzi per oro e argento
    updateMetalPrice("gold", currentGoldPrice, "gold_prices", "gold_price_history", "menu:updateGoldPrice")
    updateMetalPrice("silver", currentSilverPrice, "silver_prices", "silver_price_history", "menu:updateSilverPrice")
end, false)
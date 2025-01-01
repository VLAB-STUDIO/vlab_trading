Config = {}

Config.AuthorizedSteamHex = {
    "steam:11000014b92b665",
    -- "steam:110000112345678"
}

Config.PromptKey              = 0x760A9C6F -- ["G"]

-- SCAMBIO DI LINGOTTI D'ORO
Config.TradeLocation          = vector3(2642.69, -1296.82, 52.25) -- Locazione dell'acquisto e vendita di lingotti
Config.PromptTextTitle        = "Open State Market Menu"
Config.PromptTextDescr1       = "The market will be open from:"
Config.PromptTextDescr2       = "to:"
Config.PromptTextDescr3       = "The market is currently closed, it will reopen at:"
Config.PromptRadius           = 2.0
Config.GoldbarItemName        = "goldbar"
Config.SilverbarItemName      = "silverbar"

-- UPDATE 2.2.1
Config.GoldBarPrice           = 25.00 -- Prezzo per lingotto d'oro
Config.SilverBarPrice         = 10.00 -- Prezzo per lingotto d'argento
Config.GlobalMaxGoldBars      = 100 -- Numero massimo di lingotti d'oro acquistabili per ogni riavvio
Config.GlobalMaxSilverBars    = 50 -- Numero massimo di lingotti d'argento acquistabili per ogni riavvio
Config.BankTaxPercentage      = 10 -- Percentuale di tasse bancarie applicate agli acquisti

Config.TimerInterval          = 7200 -- Timer in secondi (2 ore di default)
Config.GoldPriceChangeRange   = {min = 0.005, max = 0.02} -- Cambio prezzo oro tra 0.5% e 2%
Config.SilverPriceChangeRange = {min = 0.003, max = 0.012} -- Cambio prezzo argento tra 0.3% e 1.2%

Config.MarketOpenHour         = 0 -- Ora di apertura della borsa
Config.MarketCloseHour        = 24 -- Ora di chiusura della borsa

Config.CommandChangePrices    = "dnikefrocio"
-- #########################

Config.MenuAlign              = "top-right"
-- #########################

Config.MenuElements           = {
    BuyIngots                 = "Buy Ingots",
    SellIngots                = "Sell Ingots",
    Gold                      = "gold",
    Silver                    = "silver",
    RemainingIngots           = "Remaining Ingots",
    SellableIngots            = "Sellable Ingots",
    ChangePrice               = "Change Price:",
    BankTaxes                 = "bank taxes",
    GraphTitle                = "Market Chart",
    GraphDesc                 = "View the state market chart",
    CloseTitle                = "Close",
    CloseDesc                 = "Close the Menu",
    MenuTitle                 = "Custom Menu",
    MenuSubText               = "Select an option",
}
-- #########################

Config.Inputs                 = {
    Confirm                   = "Confirm",
    OnlyNumber                = "Enter numbers only",
    EnterAmount               = "Enter quantity",
}
-- #########################

Config.Notifications          = {
    ClosedTrade               = "The market is currently closed.",
    ClosedTradeAndOpen        = "The market is closed! Opening hours:",
    NoCommandAuthorization    = "You are not authorized to use this command.",
    BuyError                  = "Error during purchase.",
    SellError                 = "Error during sale.",
    InvalidBuyError           = "Invalid quantity or exceeds the available limit.",
    InvalidAmount             = "Invalid quantity!",
    NewPriceIngots            = "The ingot price has been updated to:",
    YouHavePurchased          = "You have purchased",
    YouSold                   = "You have sold",
    GoldIngot                 = "gold ingots",
    SilverIngot               = "silver ingots",
    For                       = "for",
    Ingots                    = "ingots",
    PriceIngots               = "Price of",
    Updated                   = "updated to:",
    CantCarryAnyMore          = "You cannot carry more",
    InsufficientFunds         = "Insufficient funds",
    GlobalLimitReached        = "The global purchase limit for ingots has been reached.",
    SaleGlobalLimitReached    = "The global sale limit for ingots has been reached.",
}

Config.Suggestions            = {
    ChangePrices              = "Change the market value of ingots",
}
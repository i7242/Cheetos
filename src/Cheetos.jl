module Cheetos


using AlphaVantage
using BusinessDays
using Dates

include("TwilioSMS.jl")


#=
  Depends on two external services
    1. AlphaVantage: get stock price, moving average data
    2. Twilio: send SMS notification to phone
  related API key, account ID and token, should be exported to ENV
=#
AlphaVantage.global_key!(ENV["ALPHA_VANTAGE_API_KEY"])
twilio_account_sid = ENV["TWILIO_ACCOUNT_SID"]
twilio_auth_token = ENV["TWILIO_AUTH_TOKEN"]

#=
  Trading time related constants.
=#
BDAY_CALENDAR = "USNYSE"
SLEEP_TIME = 60*30

#=
  Stock price related constants.
=#

#=
  Moving average related constants.
  More details see: https://www.alphavantage.co/documentation/
  Not sure why, but ASML 120 day moving average data takes long time for response, so removed it
=#
INTERVAL = "daily"
PERIODS = [30, 60, 90]
TYPE = "close"

#= Dict for initialization:
    Symbol => (shares, avg_buy_price)
    Consider read from local config file later, maybe CSV.
=#
MY_DATA = Dict("AMZN"=>(1, 3000.0),
               "ASML"=>(2, 100.0))



#=
  Check if now is trading day and time.
    1. depends on BusinessDays.jl
    2. based on NY time
=#
function is_trading_time()
    isbday(BDAY_CALENDAR, today()) || return false
    # left some time at the end of the day
    hour(now()) >= 10 && hour(now()) <= 5
end

#=
  Get last trading day.
    1. if today is trading day, return today
    2. otherwise check and find one
=#
function last_trading_day()
    td = today()
    while !isbday(BDAY_CALENDAR, td)
        td -= Day(1)
    end
    return string(td)
end


# TODO: change to JuliaFinance packages later
#=
  Data
    1. Item
        an "Item" can be a stock or a fund.
        Keep its data updated when running.
    2. watch_list
        a list of items
=#
mutable struct Item
    symbol::String
    shares::Int64
    avg_buy_price::Float64
    cur_price::Float64
    moving_averages::Dict{Int64, Float64}
end

watch_list = []


function init_watch_list()
    for key in keys(MY_DATA)
        item = Item(key, MY_DATA[key][1], MY_DATA[key][2], 0, Dict())
        for pd in PERIODS
            td = last_trading_day()
            price = SMA(key, INTERVAL, pd, TYPE)["Technical Analysis: SMA"][td]["SMA"]
            item.moving_averages[pd] = parse(Float64, price)
        end
        push!(watch_list, item)
        @info item
    end
end

# TODO
function sync_moving_average_price()
end

# TODO
function sync_current_price()
    # tmp_data = time_series_intraday("ASML", "5min")
    # tmp_data["Time Series (5min)"]["2021-08-24 14:34:00"]["4. close"]
end

# TODO
function check_down_cross()
end

# TODO
function check_drop_percentage()
end

function watching()
    while true
        hour(now()) == 5 && sync_ma_data()
        sleep(SLEEP_TIME)
    end
end

init_watch_list()
# watching()

end # module

module Cheetos

using AlphaVantage
using BusinessDays:isbday 
using Dates:today, hour, now

include("TwilioSMS.jl")

AlphaVantage.global_key!(ENV["ALPHA_VANTAGE_API_KEY"])
twilio_account_sid = ENV["TWILIO_ACCOUNT_SID"]
twilio_auth_token = ENV["TWILIO_AUTH_TOKEN"]
twilio_from = ENV["TWILIO_FROM"]
twilio_to = ENV["TWILIO_TO"]

#=
  Trade watching time related constants.
=#
BDAY_CALENDAR = "USNYSE"
ONE_HOUR = 3600
ONE_DAY = 86400

#=
  Stock price related constants.
=#
PRICE_TYPE = "4. close"

#=
  Moving average related constants.
  More details in: https://www.alphavantage.co/documentation/
  Not sure why, some request takes long time to get response
=#
INTERVAL = "daily"
PERIODS = [30, 60, 90]
SMA_TYPE = "close"

#= Dict for initialization:
    Symbol => (shares, avg_buy_price)
    Consider read from local config file later, maybe CSV.
=#
MY_DATA = Dict("AMZN"=>(1, 3000.0),
               "ASML"=>(2, 100.0))


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


function sync_moving_average_price(tm::Item)
    for pd in PERIODS
        all_sma = SMA(tm.symbol, INTERVAL, pd, SMA_TYPE)["Technical Analysis: SMA"]
        latest_sma = all_sma[max(keys(all_sma)...)]["SMA"]
        tm.moving_averages[pd] = parse(Float64, latest_sma)
    end
    @info "synced moving average data for $(tm.symbol)"
end

function sync_current_price(tm::Item)
    all_price = time_series_intraday(tm.symbol)["Time Series (1min)"]
    latest_price = all_price[max(keys(all_price)...)][PRICE_TYPE]
    tm.cur_price = parse(Float64, latest_price)
    @info "synced latest price for $(tm.symbol)"
end

function init_watch_list()
    for key in keys(MY_DATA)
        tm = Item(key, MY_DATA[key][1], MY_DATA[key][2], 0, Dict())
        sync_moving_average_price(tm)
        sync_current_price(tm)
        push!(watch_list, tm)
    end
    @info "initialized watch list:"
    @info watch_list
end

# TODO
function check_down_cross()
end

# TODO
function check_up_cross()
end

# TODO
function check_drop_percentage()
end

function watching()
    while true
        # if !isbday(BDAY_CALENDAR, today())
        #     @info "not business day, sleep on day"
        #     sleep(ONE_DAY)
        #     continue
        # end

        cur_hour = hour(now())
        if 7 < cur_hour < 9
            for tm in watch_list
                sync_moving_average_price(tm)
            end
        end
        if 9 < cur_hour < 17
            for tm in watch_list
                sync_current_price(tm)
            end
        end
        @info "current status:"
        @info watch_list
        @info "waiting next sync"
        sleep(ONE_HOUR)
    end
end

init_watch_list()
watching()

end # module

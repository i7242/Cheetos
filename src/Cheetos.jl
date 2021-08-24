module Cheetos

include("TwilioSMS.jl")

using AlphaVantage
using Dates

# Export API key to environment variables so client here can get it.
AlphaVantage.global_key!(ENV["ALPHA_VANTAGE_API_KEY"])

# Moving average related constants.
# More details see: https://www.alphavantage.co/documentation/
INTERVAL = "daily"
PERIODS = [30, 60, 90]
TYPE = "close"

# Dict for initialization:
# Symbol => (shares, avg_buy_price)
MY_DATA = Dict("AMZN"=>(1, 3000.0),
               "ASML"=>(2, 100.0))

# An "Item" can be a stock or a fund.
#     Keep its data updated when running.
mutable struct Item
    symbol::String
    shares::Int64
    avg_buy_price::Float64
    cur_price::Float64
    moving_average::Dict{Int64, Float64}
end

watch_list = []

function init_watch_list()
    for key in keys(MY_DATA)
        item = Item(key, MY_DATA[key][1], MY_DATA[key][2], 0, Dict())
        for period in PERIODS
            # td = string(today())
            td = "2021-08-23"
            price = SMA(key, INTERVAL, period, TYPE)["Technical Analysis: SMA"][td]["SMA"]
            item.moving_average[period] = parse(Float64, price)
        end
        push!(watch_list, item)
        @info item
    end
end

init_watch_list()

function watching()
    while true
        sleep(5)
        @info watch_list
    end
end

# watching()

end # module

module TelegramBot

include("AlphaVantage.jl")

#=
  Switch to use Telegram.
  - https://t.me/Cheetos_TG_Bot

  Chained example:
  get_TGBot() |>
    get_latest_update |>
    handle_subscription! |>
    handle_random_response |>
    handle_confirm_update
=#

using HTTP, JSON, ConfigEnv
using .AlphaVantage

export TGBot,TGParcel
export get_TGBot, get_latest_update, handle_subscription!, handle_confirm_update
export handle_latest_price, handle_query_balance, handle_add_monitor!

const BOT_URL_PRE="https://api.telegram.org/bot"
const VOO="VOO"

"""
TGBot
  - hold api key of the bot
  - chat_id is used for subscription
"""
mutable struct TGBot
  api_key::String # get from ENV["CHEETOS_TG_BOT_API_KEY"]
  chat_ids::Set{String} # keep chat_id for subscribed chat
  #=
  Assume the monitor will be simple, following rule:
    - [<symbol>, <shares>, <matching_cash_in_USD>, <status_flag>]
    - ["UPRO", 10, 400.00, "true"]
  =# 
  monitor::Array{Any}
end

"""
TGParcel
  - used as route message between functions
  - like Camel/Kinkajou, or functional pipe
"""
struct TGParcel
  bot::TGBot
  body::Dict{Any,Any}
end

"""
Create TGBot:
- get api key from env
- default no subscription
"""
function get_TGBot()::TGBot
  dotenv()
  TGBot(ENV["CHEETOS_TG_BOT_API_KEY"],Set(),[])
end

"""
Send text message.
"""
function send_message(key::String, id::String, msg::String)
  HTTP.post(BOT_URL_PRE*key*"/sendMessage?chat_id="*id*"&text="*msg)
end

"""
Original response body parsed to JSON will be returned.
"""
function get_update(key::String, offset::String)::Dict{Any,Any}
  HTTP.get(BOT_URL_PRE*key*"/getUpdates?offset=$offset&limit=1").body |>
    String |>
    JSON.parse
end

"""
Only get the latest one update by set `offset=-1&limit=1`. Any message in between will be ignored.
"""
function get_latest_update(bot::TGBot)::TGParcel
  TGParcel(bot, get_update(bot.api_key, "-1"))
end

"""
Get message text from parcel.
  - assume we do have message inside
  - only use this after parcel empty check
"""
function get_parcel_message(parcel::TGParcel)::String
  parcel.body["result"][end]["message"]["text"]
end

"""
Get chat id.
  - assume get only one message form one client...
  - only use this after parcel empty check
"""
function get_chat_id(parcel::TGParcel)::String
  parcel.body["result"][end]["message"]["chat"]["id"] |> string
end

"""
Get update id.
  - only use this after parcel empty check
"""
function get_update_id(parcel::TGParcel)::String
  parcel.body["result"][end]["update_id"] |> string
end

"""
Always add new chat to subscription.
  - this will modify the array of chat_id inside the bot
"""
function handle_subscription!(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  chat_id = get_chat_id(parcel)
  chat_id in parcel.bot.chat_ids && return parcel
  push!(parcel.bot.chat_ids, chat_id)
  @info "added chat $chat_id to list)"
  parcel
end

"""
Handle any ticket, get prices.
"""
function handle_latest_price(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  msg = get_parcel_message(parcel)
  if (msg[1] == '$')
    try
      id = msg[2:end] |> uppercase
      df = get_latest_price(id)
      msg = "$id : {time: $(df[1,"timestamp"]), open: $(df[1,"open"]), high: $(df[1,"high"]), low: $(df[1,"low"]), close: $(df[1,"close"])}"
      @info msg
      send_message(parcel.bot.api_key, get_chat_id(parcel), msg)
    catch e
      @info e
    end
  end
  parcel
end

"""
Handle query of simple balancing ratio.
Query format with UPRO example:
    ?<symbol>?<shares>?<USDcash>
    ?UPRO?12?400
"""
function handle_query_balance(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  msg = get_parcel_message(parcel)

  # check if matches query pattern by count '?'
  bv = [c for c in msg] .== '?'
  ct = count(>(0), bv)
  if ct == 3
    try
      query = [s for s in split(msg, '?') if !isempty(s)]
      id = query[1] |> uppercase
      price = get_latest_price(id).close[1]
      shares = parse(Int64, query[2])
      cash = parse(Float64, query[3])
      ratio = round(price*shares/cash; digits=2)
      rsp = "$(id) price: $(price), number of shares: $(shares), cash: $(cash) balance ratio: $(ratio)"
      @info rsp
      send_message(parcel.bot.api_key, get_chat_id(parcel), rsp)
    catch e
        @info e
    end
  end

  parcel
end

"""
Handle add monitor for rebalancing alarm.
"""
function handle_add_monitor!(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  msg = get_parcel_message(parcel)

  # check if matches query pattern by count '@'
  bv = [c for c in msg] .== '@'
  ct = count(>(0), bv)
  if ct == 3
    try
      query = [s for s in split(msg, '@') if !isempty(s)]
      push!(query, "false")

      # set monitor in bot
      parcel.bot.monitor = query

      # following is same to handle_query_balance(), need to extract a function
      id = query[1] |> uppercase
      price = get_latest_price(id).close[1]
      shares = parse(Int64, query[2])
      cash = parse(Float64, query[3])
      ratio = round(price*shares/cash; digits=2)
      rsp = "$(id) price: $(price), number of shares: $(shares), cash: $(cash) balance ratio: $(ratio)"
      @info rsp
      send_message(parcel.bot.api_key, get_chat_id(parcel), rsp)
    catch e
        @info e
    end
  end

  parcel
end

"""
Send a request with next offset id so current message get confirmed.
- limit the number of TG API return to be only one
- return a new TGParcel with the new TG response, possiblly empty
"""
function handle_confirm_update(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  next_id = string(parse(Int64, get_update_id(parcel))+1)
  TGParcel(parcel.bot, get_update(parcel.bot.api_key, next_id))
end

end # module

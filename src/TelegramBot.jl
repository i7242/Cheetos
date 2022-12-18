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
export get_TGBot, get_latest_update
export handle_subscription!, handle_voo_smv_60, handle_random_response, handle_confirm_update

const BOT_URL_PRE="https://api.telegram.org/bot"
const SUB="SUB" # need a better code for subscription...
const VOO="VOO"

"""
TGBot
  - hold api key of the bot
  - chat_id is used for subscription
"""
struct TGBot
  api_key::String # get from ENV["CHEETOS_TG_BOT_API_KEY"]
  chat_ids::Set{String} # keep chat_id for subscribed chat
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
  TGBot(ENV["CHEETOS_TG_BOT_API_KEY"],Set())
end

"""
Only get the latest one update by set `offset=-1&limit=1`. Any message in between will be ignored.
Original response body parsed to JSON will be returned.
"""
function get_latest_update(bot::TGBot)::TGParcel
  HTTP.get(BOT_URL_PRE*bot.api_key*"/getUpdates?offset=-1&limit=1").body |>
    String |>
    JSON.parse |>
    body -> TGParcel(bot, body)
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
Add chat id to subscription if got message "SUB!".
  - this will modify the array of chat_id inside the bot
"""
function handle_subscription!(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  if (SUB == get_parcel_message(parcel))
    push!(parcel.bot.chat_ids, get_chat_id(parcel))
  end
  parcel
end

"""
VOO 60 day simple moving average.
"""
function handle_voo_smv_60(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  if (VOO == get_parcel_message(parcel))
    df = get_voo_smv_60()
    msg = "$VOO : {time: $(df[1, "time"]), SMA: $(df[1, "SMA"])}"
    @info msg
    HTTP.post(BOT_URL_PRE*parcel.bot.api_key*
              "/sendMessage?chat_id="*
              get_chat_id(parcel)*"&text="*msg)
  end
  parcel
end

"""
Send a random number.
"""
function handle_random_response(parcel::TGParcel)::TGParcel
  isempty(parcel.body["result"]) && return parcel
  HTTP.post(BOT_URL_PRE*parcel.bot.api_key*
              "/sendMessage?chat_id="*
              get_chat_id(parcel)*"&text="*string(rand()))
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
  HTTP.get(BOT_URL_PRE*parcel.bot.api_key*"/getUpdates?offset=$next_id&limit=1").body |>
    String |>
    JSON.parse |>
    body -> TGParcel(parcel.bot, body)
end

end # module
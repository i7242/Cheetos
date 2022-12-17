module TelegramBot

#=
  Switch to use Telegram.
  - https://t.me/Cheetos_TG_Bot
  - not working yet
  - the objective is to send VOO updates to previous chats (will memorize them)

  Chained example:
  get_TGBot() |>
    get_latest_update |>
    handle_subscription! |>
    handle_random_response
=#

using HTTP, JSON, ConfigEnv

export TGBot,TGParcel
export get_TGBot, get_latest_update, handle_subscription!, handle_random_response

const BOT_URL_PRE="https://api.telegram.org/bot"
const SUB="SUB"

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
Only get the latest update by set `offset=-1`. Any message in between will be ignored.
Original response body parsed to JSON will be returned.
"""
function get_latest_update(bot::TGBot)::TGParcel
  HTTP.get(BOT_URL_PRE*bot.api_key*"/getUpdates?offset=-1").body |>
    String |>
    JSON.parse |>
    body -> TGParcel(bot, body)
end

"""
Check if we have new message.
"""
function parcel_has_message(parcel::TGParcel)::Bool
  parcel.body["ok"] && !isempty(parcel.body["result"])
end

"""
Get message text from parcel.
  - assume we do have message inside
  - use this after parcel_has_message()
"""
function get_parcel_message(parcel::TGParcel)::String
  parcel.body["result"][end]["message"]["text"]
end

"""
Get chat id.
  - assume get only one message form one client...
  - use this after parcel_has_message()
"""
function get_chat_id(parcel::TGParcel)::String
  parcel.body["result"][end]["message"]["chat"]["id"] |> string
end

"""
Add chat id to subscription if got message "SUB!".
  - this will modify the array of chat_id inside the bot
"""
function handle_subscription!(parcel::TGParcel)::TGParcel
  if parcel_has_message(parcel)
    if (SUB == get_parcel_message(parcel))
      push!(parcel.bot.chat_ids, get_chat_id(parcel))
    end
  end
  parcel
end

"""
Send a random number.
"""
function handle_random_response(parcel::TGParcel)::TGParcel
  HTTP.post(BOT_URL_PRE*parcel.bot.api_key*
              "/sendMessage?chat_id="*
              get_chat_id(parcel)*"&text="*string(rand()))
  parcel
end

end # module
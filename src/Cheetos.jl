module Cheetos

include("TelegramBot.jl")
include("AlphaVantage.jl")

using BusinessDays: isbday 
using Dates: today, hour, now, dayname
using ConfigEnv

using .TelegramBot
using .AlphaVantage

export chasing

function chasing()
  @info "chasing VOO~~"
  dotenv()
  tg_bot = get_TGBot()
  while true
    tg_bot |>
      get_latest_update |>
      handle_subscription! |>
      handle_latest_price |>
      handle_confirm_update
    sleep(30) # a lazy bot...
  end
end

end # module
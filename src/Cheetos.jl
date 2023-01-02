module Cheetos

include("TelegramBot.jl")
include("AlphaVantage.jl")

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
      handle_query_balance |>
      handle_add_monitor! |>
      handle_confirm_update

      sleep(10) # a lazy bot...
  end
end

end # module

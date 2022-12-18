module AlphaVantage

using HTTP, CSV, DataFrames, ConfigEnv

export get_latest_price, get_voo_smv_60, get_voo_smv_200

dotenv()

const ALPHA_URL_PRE = "https://www.alphavantage.co/query?"
const SMA = "function=SMA&"
const VOO = "symbol=VOO&"
const WEEKLY = "interval=weekly&"
const PERIOD_60_TYPE_CLOSE = "time_period=60&series_type=close&"
const PERIOD_200_TYPE_CLOSE = "time_period=200&series_type=close&"
const CSV_TYPE = "datatype=csv&"
const API_KEY = "apikey=$(ENV["ALPHA_VANTAGE_API_KEY"])"

"""
Get latest intraday price for input id/symbol.
"""
function get_latest_price(id::String)::DataFrame
  HTTP.get(ALPHA_URL_PRE*"function=TIME_SERIES_INTRADAY&symbol="*id*
            "&interval=15min&outputsize=compact&datatype=csv&apikey="*
            ENV["ALPHA_VANTAGE_API_KEY"]).body |>
    String |>
    IOBuffer |>
    CSV.File |>
    DataFrame
end

function get_voo_smv_60()::DataFrame
  HTTP.get(ALPHA_URL_PRE*SMA*VOO*WEEKLY*PERIOD_60_TYPE_CLOSE*CSV_TYPE*API_KEY).body |>
    String |>
    IOBuffer |>
    CSV.File |>
    DataFrame
end

function get_voo_smv_200()::DataFrame
  HTTP.get(ALPHA_URL_PRE*SMA*VOO*WEEKLY*PERIOD_200_TYPE_CLOSE*CSV_TYPE*API_KEY).body |>
    String |>
    IOBuffer |>
    CSV.File |>
    DataFrame
end

end # module
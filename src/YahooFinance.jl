module YahooFinance

#=
  Requires YAHOO_API_KEY set in env.
=#
export get_quote

using HTTP, JSON

function get_quote(stock_symbol::String)::Dict{String, Any}
    yahoo_api_key = ENV["YAHOO_API_KEY"]
    request_url = "https://yfapi.net/v6/finance/quote?region=US&lang=en&symbols=$stock_symbol"
    request_header = ["X-API-KEY" => yahoo_api_key]

    return HTTP.get(request_url, request_header) |>
        r -> r.body |>
        String |>
        JSON.parse
end

end # module
module YahooFinance

export get_prices

using HTTP, JSON

function get_prices(input_symbol::String)::Dict{String, Any}

    (@isdefined yahoo_api_key) || (yahoo_api_key = ENV["YAHOO_API_KEY"])

    request_uri_prefix = "https://yfapi.net/v6/finance/quote?"
    request_uri = request_uri_prefix*HTTP.URIs.escapeuri([:region => "US", :lang => "en", :symbols => input_symbol])
    request_header = ["X-API-KEY" => yahoo_api_key]
    HTTP.get(request_uri, request_header) |>
        r -> r.body |>
        String |>
        JSON.parse
end

end # module
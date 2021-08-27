module TwilioSMS

# Thanks to this blog: https://www.twilio.com/blog/sending-sms-with-julia-and-twilio

using HTTP
using JSON

function send_sms(message, from, to)

    isdefined(twilio_account_sid) || (twilio_account_sid = ENV["TWILIO_ACCOUNT_SID"])
    isdefined(twilio_auth_token) || (twilio_auth_token = ENV["TWILIO_AUTH_TOKEN"])
    endpoint = "api.twilio.com/2010-04-01/Accounts/$twilio_account_sid/Messages.json"
    url = "https://$twilio_account_sid:$twilio_auth_token@$endpoint"

    # This is a nice function:
    #   help?> HTTP.URIs.escapeuri
    #        escapeuri(query_vals)
    #        Percent-encode and concatenate a value pair(s) as they would conventionally
    #        be encoded within the query part of a URI.
    request_body = HTTP.URIs.escapeuri([:From => from, :To => to, :Body => message])
    request_headers = ["Content-Type" => "application/x-www-form-urlencoded"]

    try
        response = HTTP.post(url, request_headers, request_body)
        return JSON.parse(String(response.body))
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            # response status was 4xx or 5xx
            # throw an error with the body of the API response
            error(JSON.parse(String(e.response.body))["message"])
        else
            # Some other kind of error, which we can't handle
            rethrow()
        end
    end
end

# result = send_sms("Hello from Twilio! ☎", ENV["TWILIO_FROM_NUMBER"], ENV["TWILIO_TO_NUMBER"])
# println(result["sid"])

end # module

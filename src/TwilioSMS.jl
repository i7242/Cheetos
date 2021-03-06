module TwilioSMS

# Thanks to this blog: https://www.twilio.com/blog/sending-sms-with-julia-and-twilio

export send_sms

using HTTP, JSON

function send_sms(message, from, to)

    (@isdefined twilio_account_sid) || (twilio_account_sid = ENV["TWILIO_ACCOUNT_SID"])
    (@isdefined twilio_auth_token) || (twilio_auth_token = ENV["TWILIO_AUTH_TOKEN"])

    endpoint = "api.twilio.com/2010-04-01/Accounts/$twilio_account_sid/Messages.json"
    url = "https://$twilio_account_sid:$twilio_auth_token@$endpoint"

    request_body = HTTP.URIs.escapeuri([:From => from, :To => to, :Body => message])
    request_headers = ["Content-Type" => "application/x-www-form-urlencoded"]

    try
        response = HTTP.post(url, request_headers, request_body)
        return JSON.parse(String(response.body))
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            error(JSON.parse(String(e.response.body))["message"])
        else
            rethrow()
        end
    end

end

end # module

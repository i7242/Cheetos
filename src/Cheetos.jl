module Cheetos

include("YahooFinance.jl")
include("TwilioSMS.jl")

using BusinessDays: isbday 
using Dates: today, hour, now, dayname

export watching

#=
  Trade watching time related constants.
=#
BDAY_CALENDAR = "USNYSE"
ONE_HOUR = 3600

function watching()
  yahoo_api_key = ENV["YAHOO_API_KEY"]
  twilio_account_sid = ENV["TWILIO_ACCOUNT_SID"]
  twilio_auth_token = ENV["TWILIO_AUTH_TOKEN"]
  twilio_from = ENV["TWILIO_FROM"]
  twilio_to = ENV["TWILIO_TO"]

  TwilioSMS.send_sms("Start to watching VOO price!", twilio_from, twilio_to)

  while true
    if dayname(today()) == "Saturday"
        TwilioSMS.send_sms("Saturday! Time to have a weekly earing review!", twilio_from, twilio_to)
    end

    b_day = isbday(BDAY_CALENDAR, today())
    cur_hour = hour(now())

    if b_day && 9 < cur_hour < 17
        prices = YahooFinance.get_prices("VOO")
        fiftyDayAvg = prices["quoteResponse"]["result"][1]["fiftyDayAverage"]
        twoHundredDayAvg = prices["quoteResponse"]["result"][1]["twoHundredDayAverage"]
        fiftyDayAvgChange = prices["quoteResponse"]["result"][1]["fiftyDayAverageChange"]
        twoHundredDayAvgChange = prices["quoteResponse"]["result"][1]["twoHundredDayAverageChange"]

        if(fiftyDayAvgChange < 0 || twoHundredDayAvgChange < 0)
          TwilioSMS.send_sms("VOO 50 day change $(fiftyDayAvgChange)($(fiftyDayAvgChange/fiftyDayAvg)%), 200 day change $(twoHundredDayAvgChange)($(twoHundredDayAvgChange/twoHundredDayAvg)%)",
                              twilio_from, twilio_to)
        end
    end
    
    sleep(ONE_HOUR)
  end
end

end # module

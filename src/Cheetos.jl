module Cheetos

include("YahooFinance.jl")
include("TwilioSMS.jl")

using BusinessDays: isbday 
using Dates: today, hour, now, dayname

export watching

#=
  Watching related constants.
=#
VOO = "VOO"
BDAY_CALENDAR = "USNYSE"
ONE_HOUR = 3600

function watching()

  #=
    Get the latest keys before running. However, will double check in each module.
  =#
  yahoo_api_key = ENV["YAHOO_API_KEY"]
  twilio_account_sid = ENV["TWILIO_ACCOUNT_SID"]
  twilio_auth_token = ENV["TWILIO_AUTH_TOKEN"]
  twilio_from = ENV["TWILIO_FROM"]
  twilio_to = ENV["TWILIO_TO"]

  TwilioSMS.send_sms("Start to watching VOO price!", twilio_from, twilio_to)

  while true

    if isbday(BDAY_CALENDAR, today())
      #=
        Only check in the middle of the day.
      =#
      if 12 < hour(now()) < 14
        data = YahooFinance.get_prices(VOO)["quoteResponse"]["result"][1]
        fiftyDayAvgChangePercent = data["fiftyDayAverageChangePercent"]
        twoHundredDayAvgChangePercent = data["twoHundredDayAverageChangePercent"]
        regularMarketPrice = data["regularMarketPrice"]
        fiftyTwoWeekLow = data["fiftyTwoWeekLow"]

        if (fiftyDayAvgChangePercent < 0 || twoHundredDayAvgChangePercent < 0)
          TwilioSMS.send_sms(
            "VOO 50 day change percent: $fiftyDayAverageChangePercent%, 200 day change percent $twoHundredDayAverageChangePercent%",
            twilio_from, twilio_to)
        end

        if regularMarketPrice == fiftyTwoWeekLow
          TwilioSMS.send_sms(
            "Current VOO price $regularMarketPrice is the lowest in the past 52 weeks.",
            twilio_from, twilio_to)
        end

        sleep(ONE_HOUR*4)
      end

    end
    
    sleep(ONE_HOUR)
  end

end

end # module

module Cheetos

include("YahooFinance.jl")
include("TelegramBot.jl")
include("AlphaVantage.jl")

using BusinessDays: isbday 
using Dates: today, hour, now, dayname
using ConfigEnv

# export watching

#=
  Load config to ENV, like API key
=#
dotenv()

#=
  Related constants.
=#
VOO = "VOO"
BDAY_CALENDAR = "USNYSE"
ONE_HOUR = 3600

function watching()

#  TwilioSMS.send_sms("Start to watching VOO price!", twilio_from, twilio_to)
#
#  while true
#
#    if isbday(BDAY_CALENDAR, today())
#      #=
#        Only check in the middle of the day.
#      =#
#      if 12 < hour(now()) < 14
#        data = YahooFinance.get_prices(VOO)["quoteResponse"]["result"][1]
#        fiftyDayAvgChangePercent = data["fiftyDayAverageChangePercent"]
#        twoHundredDayAvgChangePercent = data["twoHundredDayAverageChangePercent"]
#        regularMarketPrice = data["regularMarketPrice"]
#        fiftyTwoWeekLow = data["fiftyTwoWeekLow"]
#
#        if (fiftyDayAvgChangePercent < 0 || twoHundredDayAvgChangePercent < 0)
#          TwilioSMS.send_sms(
#            "VOO 50 day change percent: $fiftyDayAverageChangePercent%, 200 day change percent $twoHundredDayAverageChangePercent%",
#            twilio_from, twilio_to)
#        end
#
#        if regularMarketPrice == fiftyTwoWeekLow
#          TwilioSMS.send_sms(
#            "Current VOO price $regularMarketPrice is the lowest in the past 52 weeks.",
#            twilio_from, twilio_to)
#        end
#
#        sleep(ONE_HOUR*4)
#      end
#
#    end
#    
#    sleep(ONE_HOUR)
#  end

end

end # module

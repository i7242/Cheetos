# Cheetos
Watching the VOO price changes.

## TODO
-[ ] move to use Telegram


## Run

```
cd Cheetos
julia --project run.jl
```

## Note

- Arc/Manjaro use this Julia AUR: https://aur.archlinux.org/packages/julia-bin
- Data, like API key, need to be saved into `.env`, including:
  - YAHOO_API_KEY
  - CHEETOS_TG_BOT_API_KEY
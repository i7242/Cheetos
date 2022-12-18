# Cheetos
Watching the VOO price changes.

## TODO
- [x] move to use Telegram
- [ ] customize TG send messages
- [ ] define general timer utils
- [ ] add timestamp into TGBot struct


## Run

```
cd Cheetos
julia --project chasing.jl
```

## Note

- Arc/Manjaro use this Julia AUR: https://aur.archlinux.org/packages/julia-bin
- Data, like API key, need to be saved into `.env`, including:
  - CHEETOS_TG_BOT_API_KEY
  - ALPHA_VANTAGE_API_KEY
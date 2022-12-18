# Cheetos
Watching the VOO price changes.

## TODO
- [ ] customize TG send messages
- [ ] define general timer utils
- [ ] add timestamp into TGBot struct


## Run

- update the working `dir` in `chasing.jl`
- regist a command to starrt `chasing.jl` to `systemd` and let it auto start.


## Note

- Arc/Manjaro use this Julia AUR: https://aur.archlinux.org/packages/julia-bin
- but in RespberryPi, use the aarch_64 version Julia
- consider to setup a local registry to load the Cheetos pkg
- data, like API key, need to be saved into `.env`, including:
  - CHEETOS_TG_BOT_API_KEY
  - ALPHA_VANTAGE_API_KEY
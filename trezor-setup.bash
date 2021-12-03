cd ~/Documents/trezor-firmware
poetry shell
trezorctl device wipe
trezorctl device load --mnemonic "all all all all all all all all all all all all"

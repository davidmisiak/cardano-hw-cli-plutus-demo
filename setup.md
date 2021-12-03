# Fetch protocol parameters

```bash
cardano-cli query protocol-parameters \
    --out-file protocol.json \
    --testnet-magic 1097911063
```

# Prepare your HW wallet

Use a fresh mnemonic (e.g. from [here](https://particl.github.io/bip39/bip39-standalone.html)), so that there is no interference with old UTXOs.

Generate signing files and address:
```bash
cardano-hw-cli address key-gen \
    --path 1852H/1815H/0H/0/0\
    --verification-key-file payment-hw.vkey \
    --hw-signing-file payment.hwsfile

cardano-hw-cli address key-gen \
    --path 1852H/1815H/0H/2/0 \
    --verification-key-file stake-hw.vkey \
    --hw-signing-file stake.hwsfile

cardano-cli address build \
    --payment-verification-key-file payment-hw.vkey \
    --stake-verification-key-file stake-hw.vkey \
    --out-file hw.addr \
    --testnet-magic 1097911063
```

# Generate CLI keys and address

```bash
cardano-cli address key-gen \
    --verification-key-file payment-cli.vkey \
    --signing-key-file payment-cli.skey

cardano-cli stake-address key-gen \
    --verification-key-file stake-cli.vkey \
    --signing-key-file stake-cli.skey

cardano-cli address build \
    --payment-verification-key-file payment-cli.vkey \
    --stake-verification-key-file stake-cli.vkey \
    --out-file cli.addr \
    --testnet-magic 1097911063
```

Now use the [Faucet](https://testnets.cardano.org/en/testnets/cardano/tools/faucet/) to get 1000 tAda to the `cli.addr` address.

Verify you have received the funds (you should see one UTXO):
```bash
cardano-cli query utxo \
    --address $(cat cli.addr) \
    --testnet-magic 1097911063

UTXO_PREP="$(cardano-cli query utxo --address $(cat cli.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')#0"
```

# Fund the HW address

Send 100 tAda to the address controlled by HW wallet.
```bash
cardano-cli transaction build-raw \
    --alonzo-era \
    --tx-in $(echo $UTXO_PREP) \
    --tx-out $(cat hw.addr)+100000000 \
    --tx-out $(cat cli.addr)+899000000 \
    --fee 1000000 \
    --out-file tx-prep.raw

cardano-cli transaction sign \
    --tx-body-file tx-prep.raw \
    --signing-key-file payment-cli.skey \
    --out-file tx-prep.signed \
    --testnet-magic 1097911063

cardano-cli transaction submit \
    --tx-file tx-prep.signed \
    --testnet-magic 1097911063
```

Verify that HW address have received the funds (you should see one UTXO):
```bash
cardano-cli query utxo \
    --address $(cat hw.addr) \
    --testnet-magic 1097911063

UTXO_HW="$(cardano-cli query utxo --address $(cat hw.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')#0"

UTXO_CLI="$(cardano-cli query utxo --address $(cat cli.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')#1"
```

# Generate script address

The payment part of script address is given by the script, we just need to add a staking part (which may be arbitrary for now).

```bash
cardano-cli address build \
    --payment-script-file datum-equals-redeemer.plutus \
    --stake-verification-key-file stake-cli.vkey \
    --out-file script.addr \
    --testnet-magic 1097911063
```

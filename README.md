# Plutus demo

Plutus script in `datum-equals-redeemer.plutus` simply validates whether the datum referenced in the tx input equals the provided redeemer:
```haskell
mkValidator :: BuiltinData -> BuiltinData -> BuiltinData -> ()
mkValidator d r _ = if d == r then () else traceError "Not Equal"
```

We will create a transaction that sends tAda from an address controlled by a HW wallet to this script (with `chocolate` as output datum) and then another transaction that spends the funds from this script.

# Setup

Prepare `cardano-cli` and a running `cardano-node`.

Follow steps in [setup.md](./setup.md) to prepare keys, addresses and intial UTXOs.

# Build and submit the HW transaction

```bash
cardano-cli transaction build-raw \
    --alonzo-era \
    --tx-in $(echo $UTXO_HW) \
    --tx-out $(cat script.addr)+99000000 \
    --tx-out-datum-hash-value '"chocolate"' \
    --fee 1000000 \
    --out-file tx-hw.raw

cardano-hw-cli transaction transform-raw \
    --tx-body-file tx-hw.raw \
    --out-file tx-hw-transformed.raw

cardano-hw-cli transaction sign \
    --tx-body-file tx-hw-transformed.raw \
    --hw-signing-file payment.hwsfile \
    --out-file tx-hw.signed \
    --testnet-magic 1097911063

cardano-cli transaction submit \
    --tx-file tx-hw.signed \
    --testnet-magic 1097911063
```

Verify that the transaction was successful (you should see one UTXO):
```bash
cardano-cli query utxo \
    --address $(cat script.addr) \
    --testnet-magic 1097911063

UTXO_SCRIPT="$(cardano-cli query utxo --address $(cat script.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')#0"
```

# Build and submit the script transaction

```bash
cardano-cli transaction build-raw \
    --alonzo-era \
    --tx-in $(echo $UTXO_SCRIPT) \
    --tx-in-script-file datum-equals-redeemer.plutus \
    --tx-in-datum-value '"chocolate"' \
    --tx-in-redeemer-value '"chocolate"' \
    --tx-in-execution-units "(1000000000, 2000000)" \
    --tx-in-collateral $(echo $UTXO_CLI) \
    --tx-out $(cat cli.addr)+98000000 \
    --fee 1000000 \
    --out-file tx-script.raw \
    --protocol-params-file protocol.json

cardano-cli transaction sign \
    --tx-body-file tx-script.raw \
    --signing-key-file payment-cli.skey \
    --out-file tx-script.signed \
    --testnet-magic 1097911063

cardano-cli transaction submit \
    --tx-file tx-script.signed \
    --testnet-magic 1097911063
```

Verify that the transaction was successful (you should see no UTXOs):
```bash
cardano-cli query utxo \
    --address $(cat script.addr) \
    --testnet-magic 1097911063

UTXO_CLI_2="$(cardano-cli query utxo --address $(cat cli.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')#0"
```

# Cleanup

Follow steps in [cleanup.md](./cleanup.md) to return tAda to the Faucet.

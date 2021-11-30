# Plutus demo

Plutus script in `datum-equals-redeemer.plutus` simply validates whether the datum referenced in the tx input equals the provided redeemer:
```haskell
mkValidator :: BuiltinData -> BuiltinData -> BuiltinData -> ()
mkValidator d r _ = if d == r then () else traceError "Not Equal"
```

We will create a transaction that sends 100 tAda from a base address to this script (with `chocolate` as output datum) and then another transaction that sends the funds back to the base address.

# Setup

Prepare `cardano-node` and `cardano-cli`.

Run
```bash
cardano-cli query protocol-parameters \
    --out-file protocol.json \
    --testnet-magic 1097911063
```

# Generate a base address

```bash
cardano-cli address key-gen \
    --verification-key-file payment.vkey \
    --signing-key-file payment.skey

cardano-cli stake-address key-gen \
    --verification-key-file stake.vkey \
    --signing-key-file stake.skey

cardano-cli address build \
    --payment-verification-key-file payment.vkey \
    --stake-verification-key-file stake.vkey \
    --out-file payment.addr \
    --testnet-magic 1097911063
```

Now use the [Faucet](https://testnets.cardano.org/en/testnets/cardano/tools/faucet/) to get some tAda to your address.

Verify you have received the funds (you should see one utxo):
```bash
cardano-cli query utxo \
    --address $(cat payment.addr) \
    --testnet-magic 1097911063

utxo=$(cardano-cli query utxo --address $(cat payment.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')
```

# Build and submit the first transaction

```bash
cardano-cli transaction build-raw \
    --alonzo-era \
    --tx-in "$(echo $utxo)#0" \
    --tx-out $(cat script.addr)+100000000 \
    --tx-out-datum-hash-value '"chocolate"' \
    --tx-out $(cat payment.addr)+899000000 \
    --fee 1000000 \
    --out-file tx.raw

cardano-cli transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file payment.skey \
    --out-file tx.signed \
    --testnet-magic 1097911063

cardano-cli transaction submit \
    --tx-file tx.signed \
    --testnet-magic 1097911063
```

Verify that the transaction was successful (you should see one utxo):
```bash
cardano-cli query utxo \
    --address $(cat script.addr) \
    --testnet-magic 1097911063

utxo2=$(cardano-cli query utxo --address $(cat script.addr) --testnet-magic 1097911063 | awk '{w=$1} END{print w}')
```

# Build and submit the second transaction

```bash
cardano-cli transaction build-raw \
    --alonzo-era \
    --tx-in "$(echo $utxo2)#0" \
    --tx-in-script-file datum-equals-redeemer.plutus \
    --tx-in-datum-value '"chocolate"' \
    --tx-in-redeemer-value '"chocolate"' \
    --tx-in-execution-units "(1000000000, 2000000)" \
    --tx-in-collateral "$(echo $utxo2)#1" \
    --tx-out $(cat payment.addr)+99000000 \
    --fee 1000000 \
    --out-file tx2.raw \
    --protocol-params-file protocol.json

cardano-cli transaction sign \
    --tx-body-file tx2.raw \
    --signing-key-file payment.skey \
    --out-file tx2.signed \
    --testnet-magic 1097911063

cardano-cli transaction submit \
    --tx-file tx2.signed \
    --testnet-magic 1097911063
```

Verify that the transaction was successful (you should see no utxos):
```bash
cardano-cli query utxo \
    --address $(cat script.addr) \
    --testnet-magic 1097911063
```

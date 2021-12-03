# Return funds to the Faucet

Note: Check whether the two UTXOs are set correctly (possibly set them manually):
```bash
cardano-cli query utxo \
    --address $(cat cli.addr) \
    --testnet-magic 1097911063

echo $UTXO_CLI
echo $UTXO_CLI_2
```

Return tAda to the Faucet:
```bash
cardano-cli transaction build-raw \
    --alonzo-era \
    --tx-in $(echo $UTXO_CLI) \
    --tx-in $(echo $UTXO_CLI_2) \
    --tx-out addr_test1qqr585tvlc7ylnqvz8pyqwauzrdu0mxag3m7q56grgmgu7sxu2hyfhlkwuxupa9d5085eunq2qywy7hvmvej456flknswgndm3+996000000 \
    --fee 1000000 \
    --out-file tx-cleanup.raw

cardano-cli transaction sign \
    --tx-body-file tx-cleanup.raw \
    --signing-key-file payment-cli.skey \
    --out-file tx-cleanup.signed \
    --testnet-magic 1097911063

cardano-cli transaction submit \
    --tx-file tx-cleanup.signed\
    --testnet-magic 1097911063
```

Verify that the transaction was successful (you should see no UTXOs):
```bash
cardano-cli query utxo \
    --address $(cat cli.addr) \
    --testnet-magic 1097911063
```

# Clean up the files

```bash
rm protocol.json *.addr *.vkey *.skey *.hwsfile *.raw *.signed
```

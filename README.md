install foundry

### Deploying
`% export $(cat .env | xargs) && forge create --chain $CHAIN --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY src/SquadzEngine.sol:SquadzEngine`

### Verifying
Paste deployed address into .env CONTRACT_ADDRESS

`% export $(cat .env | xargs) && forge verify-contract --chain-id $CHAIN_ID --num-of-optimizations $OPTIMIZER_RUNS --compiler-version $COMPILER_VERSION <contract address> src/SquadzEngine.sol:SquadzEngine $ETHERSCAN_API_KEY`

Check verification status:

`% export $(cat .env | xargs) && forge verify-check --chain-id $CHAIN_ID <GUID> $ETHERSCAN_API_KEY`
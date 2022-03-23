install foundry

### Deploying
`% export $(cat .env.<network> | xargs) && forge create --chain $CHAIN --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $CONSTRUCTOR_ARGS --rpc-url $RPC_URL src/SquadzEngine.sol:SquadzEngine > ./deployments/$NAME.txt`

### Verifying
Find the abi-encoded constructor args with `cast abi-encode "constructor(address)" 0x0000000000000000000000000000000000000000` and add them into .env.<network> ABI_ENCODED_ARGS

Paste deployed address into .env.<network> CONTRACT_ADDRESS

`% export $(cat .env.<network> | xargs) && forge verify-contract --chain-id $CHAIN_ID --num-of-optimizations $OPTIMIZER_RUNS --constructor-args $ABI_ENCODED_ARGS --compiler-version $COMPILER_VERSION <contract address> src/SquadzEngine.sol:SquadzEngine $ETHERSCAN_API_KEY > ./deployments/verifications/$NAME-submission.txt`

Check verification status:

`% export $(cat .env.<network> | xargs) && forge verify-check --chain-id $CHAIN_ID <GUID> $ETHERSCAN_API_KEY > ./deployments/verifications/$NAME-confirmation.txt`
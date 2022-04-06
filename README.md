install foundry

## Deploying

### ShieldsPSVG
Paste deployed address of ShieldsAPI into .env.<network> SHIELDS_API_ADDRESS

`% export $(cat .env.<network> | xargs) && forge create --chain $CHAIN --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $SHIELDS_API_ADDRESS --rpc-url $RPC_URL src/lib/ShieldsPSVG.sol:ShieldsPSVG | tee ./deployments/$FOLDER/ShieldsPSVG-deployed.txt`

### PersonalizedSVG
`% export $(cat .env.<network> | xargs) && forge create --chain $CHAIN --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $RPC_URL src/lib/PersonalizedSVG.sol:PersonalizedSVG | tee ./deployments/$FOLDER/PersonalizedSVG-deployed.txt`

### SquadzEngine
Paste deployed address of PersonalizedSVG or ShieldsPSVG into .env.<network> SVG_CONTRACT_ADDRESS

`% export $(cat .env.<network> | xargs) && forge create --chain $CHAIN --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $NAMES_ADDRESS $SVG_CONTRACT_ADDRESS --rpc-url $RPC_URL src/SquadzEngine.sol:SquadzEngine | tee ./deployments/$FOLDER/SquadzEngine-deployed.txt`

## Verifying

### ShieldsPSVG
Paste deployed address into .env.<network> SVG_CONTRACT_ADDRESS

`% export $(cat .env.<network> | xargs) && forge verify-contract --chain-id $CHAIN_ID --num-of-optimizations $OPTIMIZER_RUNS --compiler-version $COMPILER_VERSION $SVG_CONTRACT_ADDRESS src/lib/ShieldsPSVG.sol:ShieldsPSVG $ETHERSCAN_API_KEY | tee ./deployments/$FOLDER/ShieldsPSVG-verify-submitted.txt`

Check verification status:

`% export $(cat .env.<network> | xargs) && forge verify-check --chain-id $CHAIN_ID <GUID> $ETHERSCAN_API_KEY | tee ./deployments/$FOLDER/ShieldsPSVG-verify-confirmed.txt`

### PersonalizedSVG
Paste deployed address into .env.<network> SVG_CONTRACT_ADDRESS

`% export $(cat .env.<network> | xargs) && forge verify-contract --chain-id $CHAIN_ID --num-of-optimizations $OPTIMIZER_RUNS --compiler-version $COMPILER_VERSION $SVG_CONTRACT_ADDRESS src/lib/PersonalizedSVG.sol:PersonalizedSVG $ETHERSCAN_API_KEY | tee ./deployments/$FOLDER/PersonalizedSVG-verify-submitted.txt`

Check verification status:

`% export $(cat .env.<network> | xargs) && forge verify-check --chain-id $CHAIN_ID <GUID> $ETHERSCAN_API_KEY | tee ./deployments/$FOLDER/PersonalizedSVG-verify-confirmed.txt`

### SquadzEngine
Find the abi-encoded constructor args with 

`% export $(cat .env.<network> | xargs) && cast abi-encode "constructor(address,address)" $NAMES_ADDRESS $SVG_CONTRACT_ADDRESS` 

and add them into .env.<network> ABI_ENCODED_ARGS

Paste deployed address of the engine into .env.<network> ENGINE_CONTRACT_ADDRESS

`% export $(cat .env.<network> | xargs) && forge verify-contract --chain-id $CHAIN_ID --num-of-optimizations $OPTIMIZER_RUNS --constructor-args $ABI_ENCODED_ARGS --compiler-version $COMPILER_VERSION $ENGINE_CONTRACT_ADDRESS src/SquadzEngine.sol:SquadzEngine $ETHERSCAN_API_KEY | tee ./deployments/$FOLDER/SquadzEngine-verify-submitted.txt`

Check verification status:

`% export $(cat .env.<network> | xargs) && forge verify-check --chain-id $CHAIN_ID <GUID> $ETHERSCAN_API_KEY | tee ./deployments/$FOLDER/SquadzEngine-verify-confirmed.txt`
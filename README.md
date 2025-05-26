# Yield Optimizer for Starknet DeFi Spring 

```bash
# Declare & Deploy Router contract
$ starkli declare target/dev/starknet_hackathon_Router.contract_class.json
$ starkli deploy $ROUTER_CLASS_HASH $OWNER_ADDRESS 

# Declare & Deploy PT Token contract
$ starkli declare target/dev/starknet_hackathon_Market.contract_class.json
$ starkli deploy $PT_TOKEN_CLASS_HASH $OWNER_ADDRESS $MARKET_NAME $UNDERLYING_ASSET $PT_TOKEN $YT_TOKEN $MATURITY_TIMESTAMP

# Declare & Deploy YT Token contract
$ starkli declare target/dev/starknet_hackathon_YieldToken.contract_class.json
$ starkli deploy $YT_TOKEN_CLASS_HASH $NAME $SYMBOL $DECIMALS

# Declare & Deploy Market contract
$ starkli declare target/dev/starknet_hackathon_Market.contract_class.json
$ starkli deploy $MARKET_CLASS_HASH $OWNER_ADDRESS $MARKET_NAME $UNDERLYING_ASSET $PT_TOKEN $YT_TOKEN $MATURITY_TIMESTAMP
```
use starknet::ContractAddress;

#[starknet::interface]
pub trait IYieldToken<TContractState> {
    fn underlying_asset_address(self: @TContractState) -> ContractAddress;

    fn set_market_address(ref self: TContractState, market_address: ContractAddress);
    fn mint(
        ref self: TContractState,
        caller: ContractAddress,
        on_behalf_of: ContractAddress,
        amount: u256,
        liquidity_index: u256,
    ) -> bool;
    fn burn(
        ref self: TContractState,
        from: ContractAddress,
        receiver_of_underlying: ContractAddress,
        amount: u256,
        liquidity_index: u256,
    ) -> bool;
    fn transfer(ref self: TContractState) -> bool;
}

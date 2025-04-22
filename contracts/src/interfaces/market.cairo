use starknet::ContractAddress;

#[starknet::interface]
pub trait IMarket<TContractState> {
    fn underlying_asset_address(self: @TContractState) -> ContractAddress;
    fn maturity_timestamp(self: @TContractState) -> u64;
    fn is_mature(self: @TContractState) -> bool;
    fn get_liquidity_index(self: @TContractState) -> u256;
    fn preview_redeem_yt(self: @TContractState, user: ContractAddress) -> u256;
    fn preview_yield(self: @TContractState, user: ContractAddress, future_time: u64) -> u256;
    fn total_assets(self: @TContractState) -> u256;

    fn update_liquidity_index(ref self: TContractState, apr: u256);
    fn deposit(ref self: TContractState, caller: ContractAddress, amount: u256);
    fn claim_yield(ref self: TContractState) -> u256;
    fn claim_underlying(ref self: TContractState);
}

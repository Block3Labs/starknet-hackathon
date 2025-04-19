use starknet::ContractAddress;

#[starknet::interface]
pub trait IMarket<TContractState> {
    fn underlying_asset_address(self: @TContractState) -> ContractAddress;
    fn maturity_timestamp(self: @TContractState) -> u64;
    fn get_liquidity_index(self: @TContractState) -> u256;

    fn update_liquidity_index(ref self: TContractState);
    fn deposit(ref self: TContractState, amount: u256);
    fn redeem_yt(ref self: TContractState);
    fn redeem_pt(ref self: TContractState);
}

use starknet::ContractAddress;

#[starknet::interface]
pub trait IScaledBalanceToken<TContractState> {
    fn scaled_balance_of(self: @TContractState, user: ContractAddress) -> u256;
    fn balance_of(self: @TContractState, user: ContractAddress, liquidity_index: u256) -> u256;
    fn scaled_total_supply(self: @TContractState, liquidity_index: u256) -> u256;
}

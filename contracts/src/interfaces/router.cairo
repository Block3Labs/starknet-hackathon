use starknet::ContractAddress;

#[starknet::interface]
pub trait IRouter<TContractState> {
    fn swap_underlying_for_pt(
        ref self: TContractState, market_address: ContractAddress, amount: u256,
    );
    fn swap_underlying_for_yt(
        ref self: TContractState, market_address: ContractAddress, amount: u256,
    );
    fn swap_yt_for_underlying(
        ref self: TContractState, market_address: ContractAddress, amount: u256,
    );
}

use starknet::{ClassHash, ContractAddress};
use starknet_hackathon::interfaces::market::{IMarketDispatcher};

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    fn exists(self: @TContractState, token_address: ContractAddress) -> bool;

    fn get_last_deployed_yt(self: @TContractState) -> ContractAddress;
    fn get_last_deployed_pt(self: @TContractState) -> ContractAddress;

    fn get_pt_id(self: @TContractState, token_address: ContractAddress) -> u256;
    fn get_yt_id(self: @TContractState, token_address: ContractAddress) -> u256;

    fn deploy_yield_token(
        ref self: TContractState,
        market: IMarketDispatcher,
        name: ByteArray,
        symbol: ByteArray,
        decimals: u256,
    ) -> ContractAddress;

    fn deploy_principal_token(
        ref self: TContractState,
        market: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        decimals: u256,
    ) -> ContractAddress;

    fn set_principal_token_class_hash(ref self: TContractState, contract_class_hash: ClassHash);

    fn set_yield_token_class_hash(ref self: TContractState, contract_class_hash: ClassHash);

    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

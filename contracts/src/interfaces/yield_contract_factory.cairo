use starknet::{ClassHash, ContractAddress};
use starknet_hackathon::interfaces::market::{IMarketDispatcher};

#[starknet::interface]
pub trait ITokenFactory<TContractState> {
    fn exists(self: @TContractState, token_address: ContractAddress) -> bool;

    fn get_last_deployed_token(self: @TContractState) -> ContractAddress;
    fn get_token_id(self: @TContractState, token_address: ContractAddress) -> u256;
    fn deploy_new_token(
        ref self: TContractState,
        contract_class_hash: ClassHash,
        market: IMarketDispatcher,
        name: ByteArray,
        symbol: ByteArray,
        decimals: u256,
    ) -> ContractAddress;


    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}

use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
pub trait IPrincipalToken<TContractState> {
    fn underlying_asset_address(self: @TContractState) -> ContractAddress;
}

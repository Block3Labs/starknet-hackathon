use starknet::{ClassHash, ContractAddress};
#[derive(Drop, Serde)]
pub struct Claim {
    pub id: u64,
    pub claime: ContractAddress,
    pub amount: u128,
}

#[starknet::interface]
pub trait IDefiSpring<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
    fn claim(ref self: TContractState, address: ContractAddress);
    fn get_apr(self: @TContractState) -> u256;
    fn update_apr(ref self: TContractState, new_apr: u256);
}

use starknet::{ClassHash, ContractAddress};
#[derive(Drop, Serde)]
pub struct Claim {
    pub id: u64,
    pub claime: ContractAddress,
    pub amount: u128,
}

#[starknet::interface]
pub trait IDefiSpring<TComponentState> {
    fn upgrade(ref self: TComponentState, new_class_hash: ClassHash);
    fn claim(ref self: TComponentState, address: ContractAddress);
    fn get_apr(self: @TComponentState) -> u256;
    fn set_apr(ref self: TComponentState, newIndex: u256);
    fn update_apr(ref self: TComponentState, newIndex: u256);
}

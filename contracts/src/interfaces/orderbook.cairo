use starknet::ContractAddress;
use starknet_hackathon::contracts::orderbook::OrderBook::{Order};
#[starknet::interface]
pub trait IOrderBook<TContractState> {
    fn create_order(ref self: TContractState, amount: u256, caller: ContractAddress);
    fn fulfill_order(ref self: TContractState, order_id: u256);
    fn buy_order_market(ref self: TContractState);
    fn get_order(self: @TContractState, order_id: u256) -> Order;
    fn get_orders_length(self: @TContractState) -> u256;
}

#[starknet::interface]
trait IOracleComponent<TContractState> {
    fn get_asset_price(self: @TContractState, pair_id: felt252) -> u128;
}

#[starknet::component]
pub mod OracleComponent {
    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::PragmaPricesResponse;

    const pragma_contract: ContractAddress = 0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a.try_into().unwrap();

    #[storage]
    pub struct Storage {}

    #[embeddable_as(OracleImpl)]
    impl Oracle<
        TContractState, +HasComponent<TContractState>
    > of super::IOracleComponent<ComponentState<TContractState>> {
        fn get_asset_price(self: @TContractState, pair_id: felt252) -> u128 {
            let oracle_dispatcher = IPragmaABIDispatcher { contract_address: pragma_contract };
            let output: PragmaPricesResponse = oracle_dispatcher.get_data_median(DataType::SpotEntry(asset_id));
            return output.price;
        }
    }   
}
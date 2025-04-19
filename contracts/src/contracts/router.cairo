#[starknet::contract]
pub mod Router {
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{ContractAddress, get_caller_address};
    use starknet_hackathon::interfaces::market::{IMarketDispatcher, IMarketDispatcherTrait};
    use starknet_hackathon::interfaces::router::IRouter;

    #[storage]
    struct Storage {}

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Deposit {
        #[key]
        user: ContractAddress,
        amount: u256,
        pt_received: u256,
        yt_locked: u256,
        liquidity_index: u256,
    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Deposit: Deposit,
    }

    mod Errors {
        pub const INVALID_BALANCE: felt252 = 'Invalid market balance';
    }

    #[abi(embed_v0)]
    impl Router of IRouter<ContractState> {
        // Dont' forget to approve underlying_token.approve(router, amount)
        fn swap_underlying_for_pt(
            ref self: ContractState, market_address: ContractAddress, amount: u256,
        ) {
            let caller = get_caller_address();

            let underlying_token = IERC20Dispatcher { contract_address: market_address };
            underlying_token.transfer_from(caller, market_address, amount);
            assert(underlying_token.balance_of(market_address) == amount, Errors::INVALID_BALANCE);

            let market = IMarketDispatcher { contract_address: market_address };
            let liquidity_index = market.get_liquidity_index();
            market.deposit(caller, amount);

            // create_order()

            self
                .emit(
                    Deposit {
                        user: caller,
                        amount,
                        pt_received: amount,
                        yt_locked: amount,
                        liquidity_index,
                    },
                );
        }

        fn swap_yt_for_underlying(
            ref self: ContractState, market_address: ContractAddress, amount: u256,
        ) {// je sais pas encore le nom de ma fonction
        // fulfill_order
        }
    }
}

#[starknet::contract]
pub mod Router {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};
    use starknet_hackathon::interfaces::market::{IMarketDispatcher, IMarketDispatcherTrait};
    use starknet_hackathon::interfaces::orderbook::{
        IOrderBookDispatcher, IOrderBookDispatcherTrait,
    };
    use starknet_hackathon::interfaces::router::IRouter;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        order_book_addr: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Deposit {
        #[key]
        user: ContractAddress,
        amount: u256,
        pt_received: u256,
        yt_locked: u256,
    }

    #[event]
    #[derive(Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Deposit: Deposit,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    mod Errors {
        pub const INVALID_BALANCE: felt252 = 'Invalid market balance';
        pub const INVALID_SWAP_AMOUNT: felt252 = 'Amount must be greater than 0';
        pub const INSUFFICIENT_BALANCE: felt252 = 'Insufficient balance';
        pub const INVALID_MATURITY: felt252 = 'Market not matured yet';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl Router of IRouter<ContractState> {
        fn swap_underlying_for_pt(
            ref self: ContractState, market_address: ContractAddress, amount: u256,
        ) {
            assert(amount != 0, Errors::INVALID_SWAP_AMOUNT);
            let caller = get_caller_address();
            let market = IMarketDispatcher { contract_address: market_address };
            let underlying_token = IERC20Dispatcher {
                contract_address: market.underlying_asset_address(),
            };
            assert(underlying_token.balance_of(caller) >= amount, Errors::INSUFFICIENT_BALANCE);

            let previous_balance = underlying_token.balance_of(market_address);
            underlying_token.transfer_from(caller, market_address, amount);
            assert(
                previous_balance + amount == underlying_token.balance_of(market_address),
                Errors::INVALID_BALANCE,
            );

            market.deposit(caller, amount);

            let orderbook = IOrderBookDispatcher { contract_address: market.orderbook_address() };
            orderbook.create_order(amount, caller);

            self.emit(Deposit { user: caller, amount, pt_received: amount, yt_locked: amount });
        }

        // si quelqu'un buy les yt
        fn swap_underlying_for_yt(
            ref self: ContractState, market_address: ContractAddress, order_id: u256,
        ) {
            let caller = get_caller_address();
            let market = IMarketDispatcher { contract_address: market_address };
            let orderbook = IOrderBookDispatcher { contract_address: market.orderbook_address() };
            let underlying_token = IERC20Dispatcher {
                contract_address: market.underlying_asset_address(),
            };

            let order = orderbook.get_order(order_id);
            assert(
                underlying_token.balance_of(caller) >= order.amount, Errors::INSUFFICIENT_BALANCE,
            );

            market.buy_yield(caller, order.seller, order.amount);
            // fulfill_order()
        }

        // A la fin de la maturité
        fn swap_yt_for_underlying(
            ref self: ContractState,
            market_address: ContractAddress,
            yt_address: ContractAddress,
            amount: u256,
        ) {
            assert(amount != 0, Errors::INVALID_SWAP_AMOUNT);

            let caller = get_caller_address();
            let market = IMarketDispatcher { contract_address: market_address };
            let maturity = market.maturity_timestamp();
            assert(get_block_timestamp() > maturity, Errors::INVALID_MATURITY);
            let yt_token = IERC20Dispatcher { contract_address: yt_address };
            assert(yt_token.balance_of(caller) > 0, Errors::INVALID_BALANCE);
            let claimable_amount = market.claim_yield(caller);
            let underlying_token = IERC20Dispatcher {
                contract_address: market.underlying_asset_address(),
            };
            underlying_token.transfer_from(market_address, caller, claimable_amount);
        }

        fn set_order_book_addr(ref self: ContractState, order_book_address: ContractAddress) {
            self.order_book_addr.write(order_book_address);
        }
        // A la fin de la maturité
    // fn swap_pt_for_underlying()
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

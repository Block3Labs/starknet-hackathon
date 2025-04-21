#[starknet::contract]
pub mod Router {
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_caller_address};
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
            let previous_balance = underlying_token.balance_of(market_address);
            underlying_token.transfer_from(caller, market_address, amount);
            assert(
                previous_balance + amount == underlying_token.balance_of(market_address),
                Errors::INVALID_BALANCE,
            );

            market.deposit(caller, amount);

            // create_order()
            let order_book = IOrderBookDispatcher { contract_address: self.order_book_addr.read() };
            order_book.create_order(amount, caller);

            self.emit(Deposit { user: caller, amount, pt_received: amount, yt_locked: amount });
        }

        // si quelqu'un buy les yt
        fn swap_underlying_for_yt(
            ref self: ContractState, market_address: ContractAddress, amount: u256,
        ) { // fulfill_order
        }

        // A la fin de la maturité
        fn swap_yt_for_underlying(
            ref self: ContractState, market_address: ContractAddress, amount: u256,
        ) {}

        fn set_order_book_addr(ref self: ContractState, order_book_address: ContractAddress) {
            self.order_book_addr.write(order_book_address);
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

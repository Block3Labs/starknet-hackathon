#[starknet::contract]
pub mod OrderBook {
    use openzeppelin_token::erc20::interface::IERC20;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress};
    use starknet_hackathon::interfaces::defi_spring::{
        IDefiSpringDispatcher, IDefiSpringDispatcherTrait,
    };
    use starknet_hackathon::interfaces::market::{IMarketDispatcher, IMarketDispatcherTrait};


    #[storage]
    pub struct Storage {
        yield_token_address: ContractAddress,
        paying_token_address: ContractAddress,
        defi_spring_address: ContractAddress,
        next_order_id: u256,
        order_list: Map::<u256, Position>,
    }

    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    pub enum Event {
        PositionListed: PositionListed,
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct PositionListed {
        #[key]
        next_oder_id: u256,
        sender: ContractAddress,
        // amount , apy ,price , lock , duration

    }

    #[derive(Copy, Drop, Serde, Hash, starknet::Store)]
    pub struct Position {
        id: u256,
        seller: ContractAddress,
        amount: u256,
        apy: u256,
        isSold: bool,
        // price: u256,
    // duration: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        yield_token_address: ContractAddress,
        token_address: ContractAddress,
        defi_spring_address: ContractAddress,
    ) {
        self.yield_token_address.write(yield_token_address);
        self.paying_token_address.write(token_address);
        self.defi_spring_address.write(defi_spring_address);
    }

    #[abi(embed_v0)]
    impl OrderBookImpl of starknet_hackathon::interfaces::orderbook::IOrderBook<ContractState> {
        fn create_order(ref self: ContractState, amount: u256, caller: ContractAddress) {
            assert(amount > 0, 'Invalid Amount');

            let apy = IDefiSpringDispatcher { contract_address: self.defi_spring_address.read() }
                .get_apr();

            // mettre le preview_redeem_yt ??
            let UserPosition = Position {
                id: self.next_order_id.read(),
                seller: caller,
                amount: amount,
                apy: apy,
                isSold: false,
            };

            self.order_list.entry(self.next_order_id.read()).write(UserPosition);

            self.next_order_id.write(self.next_order_id.read() + 1);
        }


        fn fulfill_order(ref self: ContractState, order_id: u256) {
            let order = self.order_list.entry(order_id).read();

            assert(order.isSold == false, 'order Already Sold');

            let current_order = Position {
                id: order.id,
                seller: order.seller,
                amount: order.amount,
                apy: order.apy,
                isSold: true,
            };

            self.order_list.entry(order_id).write(current_order);
        }

        //fonction buy order au market (càd last order id)
        fn buy_order_market(ref self: ContractState) {
            let last_order = self.next_order_id.read() - 1;

            let order = self.order_list.entry(last_order).read();

            assert(order.isSold == false, 'order Already Sold');

            let current_order = Position {
                id: order.id,
                seller: order.seller,
                amount: order.amount,
                apy: order.apy,
                isSold: true,
            };

            self.order_list.entry(last_order).write(current_order);
        }

        fn get_order_info(self: @ContractState, order_id: u256) -> Position {
            let order = self.order_list.entry(order_id).read();
            order
        }

        fn get_order_length(self: @ContractState) -> u256 {
            self.next_order_id.read() - 1
        }
    }
}

#[starknet::contract]
pub mod OrderBook {
    use core::num::traits::{Bounded, Zero};
    use openzeppelin_token::erc20::interface::IERC20;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
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
        order_list: Map::<u256, Order>,
        user_orders: Map::<(ContractAddress, u256), Order> //UserAddr + id => Order
    }

    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    pub enum Event {
        OrderListed: OrderListed,
        BuyOrder: BuyOrder,
        OrderFullFill: OrderFullFill,
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct OrderListed {
        #[key]
        order_id: u256,
        sender: ContractAddress,
    }
    #[derive(Copy, Drop, starknet::Event)]
    pub struct BuyOrder {
        #[key]
        order_id: u256,
        buyer: ContractAddress,
    }

    #[derive(Copy, Drop, starknet::Event)]
    pub struct OrderFullFill {
        #[key]
        order_id: u256,
        buyer: ContractAddress,
    }

    #[derive(Copy, Drop, Serde, Hash, starknet::Store)]
    pub struct Order {
        id: u256,
        pub seller: ContractAddress,
        pub amount: u256,
        apy: u256,
        isSold: bool,
        buyer: ContractAddress,
        // price: u256,// duration: u256,
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

            let UserOrder = Order {
                id: self.next_order_id.read(),
                seller: caller,
                amount: amount,
                apy: apy,
                isSold: false,
                buyer: Zero::zero(),
            };

            self.order_list.entry(self.next_order_id.read()).write(UserOrder);
            self.user_orders.entry((caller, self.next_order_id.read())).write(UserOrder);

            self.emit(OrderListed { order_id: self.next_order_id.read(), sender: caller });
            self.next_order_id.write(self.next_order_id.read() + 1);
        }


        fn fulfill_order(ref self: ContractState, order_id: u256) {
            let order = self.order_list.entry(order_id).read();

            assert(order.isSold == false, 'order Already Sold');

            let current_order = Order {
                id: order.id,
                seller: order.seller,
                amount: order.amount,
                apy: order.apy,
                isSold: true,
                buyer: get_caller_address(),
            };

            self.order_list.entry(order_id).write(current_order);
            self
                .emit(
                    OrderFullFill {
                        order_id: self.next_order_id.read(), buyer: get_caller_address(),
                    },
                );
        }

        //fonction buy order au market (càd last order id)
        fn buy_order_market(ref self: ContractState) {
            let last_order = self.next_order_id.read() - 1;

            let order = self.order_list.entry(last_order).read();

            assert(order.isSold == false, 'order Already Sold');

            let current_order = Order {
                id: order.id,
                seller: order.seller,
                amount: order.amount,
                apy: order.apy,
                isSold: true,
                buyer: get_caller_address(),
            };

            self.order_list.entry(last_order).write(current_order);
            self
                .emit(
                    BuyOrder { order_id: self.next_order_id.read(), buyer: get_caller_address() },
                );
        }

        fn get_order(self: @ContractState, order_id: u256) -> Order {
            let order = self.order_list.entry(order_id).read();
            order
        }

        fn get_orders_length(self: @ContractState) -> u256 {
            self.next_order_id.read() - 1
        }

        fn get_user_order(self: @ContractState, user: ContractAddress, id: u256) -> Order {
            self.user_orders.entry((user, id)).read()
        }

        fn exist(self: @ContractState, order_id: u256) -> bool {
            if (self.order_list.entry(order_id).read().id != 0) {
                return true;
            } else {
                return false;
            }
        }
    }
}

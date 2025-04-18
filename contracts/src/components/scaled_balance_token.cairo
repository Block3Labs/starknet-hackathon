#[starknet::component]
pub mod ScaledBalanceTokenComponent {
    use openzeppelin_token::erc20::ERC20Component;
    use openzeppelin_token::erc20::ERC20Component::InternalTrait as ERC20InternalTrait;
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet_hackathon::interfaces::scaled_balance_token::IScaledBalanceToken;
    use starknet_hackathon::utils::math::ray_wad::{RAY, ray_div};

    #[storage]
    pub struct Storage {
        total_scaled_supply: u256,
        user_scaled_balances: Map<ContractAddress, u256>,
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Mint {
        #[key]
        caller: ContractAddress,
        #[key]
        on_behalf_of: ContractAddress,
        amount: u256,
        amount_scaled: u256,
        liquidity_index: u256,
    }

    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Burn {
        #[key]
        from: ContractAddress,
        #[key]
        receiver_of_underlying: ContractAddress,
        amount: u256,
        amount_scaled: u256,
        liquidity_index: u256,
    }

    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Mint: Mint,
        Burn: Burn,
    }

    mod Errors {
        pub const INVALID_MINT_AMOUNT: felt252 = 'invalid mint amount';
        pub const INVALID_BURN_AMOUNT: felt252 = 'invalid burn amount';
        pub const INSUFFICIENT_BALANCE: felt252 = 'insufficient balance';
    }

    #[embeddable_as(ScaledBalanceTokenImpl)]
    impl ScaledBalanceToken<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC20: ERC20Component::HasComponent<TContractState>,
    > of IScaledBalanceToken<ComponentState<TContractState>> {
        // YT-Token (without interest)
        fn scaled_balance_of(self: @ComponentState<TContractState>, user: ContractAddress) -> u256 {
            self.user_scaled_balances.entry(user).read()
        }

        // Calculate real YT-Token value with interest - claimable value at maturity
        fn balance_of(
            self: @ComponentState<TContractState>, user: ContractAddress, liquidity_index: u256,
        ) -> u256 {
            (self.user_scaled_balances.entry(user).read() * liquidity_index) / RAY
        }

        // Calculate real YT-Token total supply value
        // Voir le yield actuel qui est généré - TVL du marché de YT
        fn scaled_total_supply(
            self: @ComponentState<TContractState>, liquidity_index: u256,
        ) -> u256 {
            (self.total_scaled_supply.read() * liquidity_index) / RAY
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        +Drop<TContractState>,
    > of InternalTrait<TContractState> {
        fn mint_scaled(
            ref self: ComponentState<TContractState>,
            caller: ContractAddress,
            on_behalf_of: ContractAddress,
            amount: u256,
            liquidity_index: u256,
        ) -> bool {
            let amount_scaled = ray_div(amount, liquidity_index);
            assert(amount_scaled != 0, Errors::INVALID_MINT_AMOUNT);

            let previous_scaled_balance = self.user_scaled_balances.entry(on_behalf_of).read();
            let new_scaled_balance = previous_scaled_balance + amount_scaled;
            self.user_scaled_balances.entry(on_behalf_of).write(new_scaled_balance);
            self.total_scaled_supply.write(self.total_scaled_supply.read() + amount_scaled);

            let mut erc20_component = get_dep_component_mut!(ref self, ERC20);
            erc20_component.mint(on_behalf_of, amount);

            self
                .emit(
                    Event::Mint(
                        Mint { caller, on_behalf_of, amount, amount_scaled, liquidity_index },
                    ),
                );

            previous_scaled_balance == 0
        }

        fn burn_scaled(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            receiver_of_underlying: ContractAddress,
            amount: u256,
            liquidity_index: u256,
        ) -> bool {
            let amount_scaled = ray_div(amount, liquidity_index);
            assert(amount_scaled != 0, Errors::INVALID_BURN_AMOUNT);

            let previous_scaled_balance = self.user_scaled_balances.entry(from).read();
            assert(previous_scaled_balance >= amount_scaled, Errors::INSUFFICIENT_BALANCE);

            let new_scaled_balance = previous_scaled_balance - amount_scaled;
            self.user_scaled_balances.entry(from).write(new_scaled_balance);
            self.total_scaled_supply.write(self.total_scaled_supply.read() - amount_scaled);

            let mut erc20_component = get_dep_component_mut!(ref self, ERC20);
            erc20_component.burn(from, amount);

            self
                .emit(
                    Event::Burn(
                        Burn {
                            from, receiver_of_underlying, amount, amount_scaled, liquidity_index,
                        },
                    ),
                );

            new_scaled_balance == 0
        }

        fn transfer_scaled(
            ref self: ComponentState<TContractState>,
            from: ContractAddress,
            to: ContractAddress,
            amount: u256,
            liquidity_index: u256,
        ) -> bool {
            let amount_scaled = ray_div(amount, liquidity_index);
            assert(amount_scaled != 0, Errors::INVALID_BURN_AMOUNT);

            let from_balance = self.user_scaled_balances.entry(from).read();
            assert(from_balance >= amount_scaled, Errors::INSUFFICIENT_BALANCE);

            let to_balance = self.user_scaled_balances.entry(to).read();

            self.user_scaled_balances.entry(from).write(from_balance - amount_scaled);
            self.user_scaled_balances.entry(to).write(to_balance + amount_scaled);

            let mut erc20_component = get_dep_component_mut!(ref self, ERC20);
            erc20_component.transfer(from, to, amount);

            true
        }
    }
}

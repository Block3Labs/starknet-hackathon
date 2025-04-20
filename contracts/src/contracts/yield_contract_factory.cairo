#[starknet::contract]
pub mod YieldFactoryContract {
    use core::byte_array::ByteArrayTrait;
    use core::traits::{Into, TryInto};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait as UpgradeableInternalTrait;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::syscalls::deploy_syscall;
    use starknet::{ClassHash, ContractAddress, SyscallResultTrait, get_block_timestamp};
    use starknet_hackathon::interfaces::market::{IMarketDispatcher, IMarketDispatcherTrait};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableComponentEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[storage]
    struct Storage {
        tokens_addresses: Map<u256, ContractAddress>,
        tokens_ids: Map<ContractAddress, u256>,
        next_token_id: u256,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        NewContractDeployed: NewContractDeployed,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableComponentEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct NewContractDeployed {
        #[key]
        pub id: u256,
        pub yield_token_address: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin_address: ContractAddress) {
        self.ownable.initializer(admin_address);
    }

    #[abi(embed_v0)]
    impl TokenFactoryContractImpl of starknet_hackathon::interfaces::yield_contract_factory::ITokenFactory<
        ContractState,
    > {
        fn exists(self: @ContractState, token_address: ContractAddress) -> bool {
            if self.tokens_ids.entry(token_address).read() != 0 {
                true
            } else {
                false
            }
        }

        fn get_last_deployed_token(self: @ContractState) -> ContractAddress {
            let next_id = self.next_token_id.read();
            assert(next_id > 0, 'NO_CONTRACT_DEPLOYED');
            self.tokens_addresses.entry(next_id).read()
        }

        fn get_token_id(self: @ContractState, token_address: ContractAddress) -> u256 {
            self.tokens_ids.entry(token_address).read()
        }

        fn deploy_new_token(
            ref self: ContractState,
            contract_class_hash: ClassHash,
            market: IMarketDispatcher,
            name: ByteArray,
            symbol: ByteArray,
            decimals: u256,
        ) -> ContractAddress {
            self.ownable.assert_only_owner();
            self.next_token_id.write(self.next_token_id.read() + 1);
            let admin_address = self.ownable.owner();
            let mut calldata: Array =
                array![ // market.into(), name.into(), symbol.into(), decimals.into(),
            ];

            let result = deploy_syscall(
                contract_class_hash,
                self.next_token_id.read().try_into().unwrap(),
                calldata.span(),
                false,
            );
            let (deployed_token_address, _) = result.unwrap_syscall();
            self.tokens_addresses.entry(self.next_token_id.read()).write(deployed_token_address);
            self.tokens_ids.entry(deployed_token_address).write(self.next_token_id.read());
            self
                .emit(
                    Event::NewContractDeployed(
                        NewContractDeployed {
                            id: self.next_token_id.read(),
                            yield_token_address: deployed_token_address,
                        },
                    ),
                );

            deployed_token_address
        }


        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

#[starknet::contract]
pub mod YieldFactoryContract {
    use core::traits::{Into, TryInto};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait as UpgradeableInternalTrait;
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::syscalls::deploy_syscall;
    use starknet::{ClassHash, ContractAddress, SyscallResultTrait};
    use starknet_hackathon::interfaces::market::{IMarketDispatcher};

    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableComponentEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    #[storage]
    struct Storage {
        princpal_token_class_hash: ClassHash,
        yield_token_class_hash: ClassHash,
        princpal_token_addresses: Map<u256, ContractAddress>,
        yield_token_addresses: Map<u256, ContractAddress>,
        yt_ids: Map<ContractAddress, u256>,
        pt_ids: Map<ContractAddress, u256>,
        next_yt_id: u256,
        next_pt_id: u256,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        NewPrincipalTokanDeployed: NewPrincipalTokanDeployed,
        NewYieldTokenDeployed: NewYieldTokenDeployed,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableComponentEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    pub struct NewPrincipalTokanDeployed {
        #[key]
        pub id: u256,
        pub principal_token_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct NewYieldTokenDeployed {
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
            if self.pt_ids.entry(token_address).read() != 0 {
                true
            } else {
                false
            }
        }

        fn get_last_deployed_yt(self: @ContractState) -> ContractAddress {
            let next_id = self.next_yt_id.read();
            assert(next_id > 0, 'NO_CONTRACT_DEPLOYED');
            self.yield_token_addresses.entry(next_id).read()
        }


        fn get_last_deployed_pt(self: @ContractState) -> ContractAddress {
            let next_id = self.next_pt_id.read();
            assert(next_id > 0, 'NO_CONTRACT_DEPLOYED');
            self.princpal_token_addresses.entry(next_id).read()
        }


        fn get_yt_id(self: @ContractState, token_address: ContractAddress) -> u256 {
            self.yt_ids.entry(token_address).read()
        }

        fn get_pt_id(self: @ContractState, token_address: ContractAddress) -> u256 {
            self.pt_ids.entry(token_address).read()
        }

        fn deploy_yield_token(
            ref self: ContractState,
            market: IMarketDispatcher,
            name: ByteArray,
            symbol: ByteArray,
            decimals: u256,
        ) -> ContractAddress {
            self.ownable.assert_only_owner();
            self.next_yt_id.write(self.next_yt_id.read() + 1);

            let mut calldata = array![];
            (market, name, symbol, decimals).serialize(ref calldata);

            let result = deploy_syscall(
                self.yield_token_class_hash.read(),
                self.next_yt_id.read().try_into().unwrap(),
                calldata.span(),
                false,
            );
            let (deployed_token_address, _) = result.unwrap_syscall();
            self.yield_token_addresses.entry(self.next_yt_id.read()).write(deployed_token_address);
            self.yt_ids.entry(deployed_token_address).write(self.next_yt_id.read());
            self
                .emit(
                    Event::NewYieldTokenDeployed(
                        NewYieldTokenDeployed {
                            id: self.next_yt_id.read(), yield_token_address: deployed_token_address,
                        },
                    ),
                );

            deployed_token_address
        }


        fn deploy_principal_token(
            ref self: ContractState,
            market: ContractAddress,
            name: ByteArray,
            symbol: ByteArray,
            decimals: u256,
        ) -> ContractAddress {
            self.ownable.assert_only_owner();
            self.next_pt_id.write(self.next_pt_id.read() + 1);
            let mut calldata = array![];

            (market, name, symbol, decimals).serialize(ref calldata);

            let result = deploy_syscall(
                self.princpal_token_class_hash.read(),
                self.next_pt_id.read().try_into().unwrap(),
                calldata.span(),
                false,
            );
            let (deployed_token_address, _) = result.unwrap_syscall();
            self
                .princpal_token_addresses
                .entry(self.next_pt_id.read())
                .write(deployed_token_address);
            self.pt_ids.entry(deployed_token_address).write(self.next_pt_id.read());
            self
                .emit(
                    Event::NewPrincipalTokanDeployed(
                        NewPrincipalTokanDeployed {
                            id: self.next_pt_id.read(),
                            principal_token_address: deployed_token_address,
                        },
                    ),
                );

            deployed_token_address
        }


        fn set_principal_token_class_hash(ref self: ContractState, contract_class_hash: ClassHash) {
            self.princpal_token_class_hash.write(contract_class_hash);
        }

        fn set_yield_token_class_hash(ref self: ContractState, contract_class_hash: ClassHash) {
            self.yield_token_class_hash.write(contract_class_hash);
        }


        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

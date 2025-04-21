#[starknet::contract]
pub mod DefiSpring {
    use ERC20Component::InternalTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent::InternalTrait as UpgradeableInternalTrait;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ClassHash, ContractAddress};


    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableComponentEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        decimals: u8,
        indexRate: u256,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableComponentEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: ByteArray, symbol: ByteArray) {
        self.erc20.initializer(name, symbol);
        self.indexRate.write(1000) //10% bps
    }

    #[abi(embed_v0)]
    pub impl DefiSpringImpl of starknet_hackathon::interfaces::defi_spring::IDefiSpring<
        ContractState,
    > {
        fn claim(ref self: ContractState, address: ContractAddress) {
            self.erc20.mint(address, 10);
        }

        fn get_apr(self: @ContractState) -> u256 {
            self.indexRate.read()
        }

        fn update_apr(ref self: ContractState, newIndex: u256) {
            self.indexRate.write(newIndex);
        }

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}

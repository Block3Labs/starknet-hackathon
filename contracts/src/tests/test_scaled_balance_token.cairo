#[starknet::contract]
mod MockContract {
    use openzeppelin_token::erc20::ERC20Component;
    use starknet_hackathon::components::scaled_balance_token::ScaledBalanceTokenComponent;
    use starknet_hackathon::components::scaled_balance_token::ScaledBalanceTokenComponent::ScaledBalanceTokenImpl;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(
        path: ScaledBalanceTokenComponent,
        storage: scaled_balance_token,
        event: ScaledBalanceTokenEvent,
    );

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        scaled_balance_token: ScaledBalanceTokenComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ScaledBalanceTokenEvent: ScaledBalanceTokenComponent::Event,
        ERC20Event: ERC20Component::Event,
    }

    #[abi(embed_v0)]
    impl ScaledBalanceToken =
        ScaledBalanceTokenComponent::ScaledBalanceTokenImpl<ContractState>;
    impl ScaledBalanceTokenInternalImpl = ScaledBalanceTokenComponent::InternalImpl<ContractState>;
}
use starknet_hackathon::components::scaled_balance_token::ScaledBalanceTokenComponent;
use starknet_hackathon::components::scaled_balance_token::ScaledBalanceTokenComponent::ScaledBalanceTokenImpl;

type TestingState = ScaledBalanceTokenComponent::ComponentState<MockContract::ContractState>;

impl TestingStateDefault of Default<TestingState> {
    fn default() -> TestingState {
        ScaledBalanceTokenComponent::component_state_for_testing()
    }
}
use snforge_std::{load, map_entry_address, store, test_address};
use starknet::{ContractAddress, contract_address_const};
use starknet_hackathon::utils::math::ray_wad::{RAY, ray_div, ray_mul, ray_to_wad};

fn user() -> ContractAddress {
    contract_address_const::<'user'>()
}

pub fn calculate_liquidity_index(delta_time: u256) -> u256 {
    let apr_bps = 350_u256; // APR = 3.5%
    let bps_denominator = 10_000_u256;
    let seconds_per_year = 31_536_000_u256;
    // APR en Ray (ex: 350 / 10_000 = 0.035 * RAY)
    let apr_decimal = ray_div(apr_bps, bps_denominator);
    let time_fraction = ray_div(delta_time, seconds_per_year);
    // interest = APR * (delta_time / seconds_per_year)
    let interest = ray_mul(apr_decimal, time_fraction);
    // liquidityIndex = 1.0 * RAY + interest
    RAY + interest
}

fn store_in_user_scaled_balances(amount: u256) {
    let test_address: ContractAddress = test_address();
    store(
        test_address,
        map_entry_address(selector!("user_scaled_balances"), array![user().into()].span()),
        array![amount.try_into().unwrap()].span(),
    );
    let loaded = load(
        test_address,
        map_entry_address(selector!("user_scaled_balances"), array![user().into()].span()),
        1,
    );
    assert(loaded == array![amount.try_into().unwrap()], 'invalid storage');
}

fn compute_user_yield(liquidity_index: u256) -> (u256, u256, u256) {
    let mut scaled_balance_token: TestingState = Default::default();
    let scaled = scaled_balance_token.scaled_balance_of(user());
    let balance = scaled_balance_token.balance_of(user(), liquidity_index);
    let yield_generated = balance - scaled;
    println!("Liquity index: {}", liquidity_index);
    println!("Balance: {} YT-STRK", balance);
    println!("Yield readable: {} STRK", ray_to_wad(yield_generated));
    (scaled, balance, yield_generated)
}

#[test]
fn test_scaled_balance_of() {
    let mut scaled_balance_token: TestingState = Default::default();

    let amount = 1000000000000000000000; // 1000 STRK
    store_in_user_scaled_balances(amount);

    let scaled_balance = scaled_balance_token.scaled_balance_of(user());
    assert(scaled_balance == amount, 'invalid scaled_balance');
}

#[test]
fn test_balance_of() {
    let mut scaled_balance_token: TestingState = Default::default();

    let amount = 1000000000000000000000; // 1000 STRK
    store_in_user_scaled_balances(amount);

    println!("Scaled balance: {} PT-STRK", scaled_balance_token.scaled_balance_of(user()));

    let liquidity_index = calculate_liquidity_index(86_400_u256);
    println!("-----Today-----");
    let (scaled, balance, _) = compute_user_yield(liquidity_index);
    let expected = ray_mul(scaled, liquidity_index);
    assert(balance == expected, 'today: balance_of failed');

    let liquidity_index = calculate_liquidity_index(172_800_u256);
    println!("-----Tomorrow-----");
    let (scaled, balance, _) = compute_user_yield(liquidity_index);
    let expected = ray_mul(scaled, liquidity_index);
    assert(balance == expected, 'tomorrow: balance_of failed');

    let liquidity_index = calculate_liquidity_index(604_800_u256);
    println!("-----Week-----");
    let (scaled, balance, _) = compute_user_yield(liquidity_index);
    let expected = ray_mul(scaled, liquidity_index);
    assert(balance == expected, 'week: balance_of failed');

    let liquidity_index = calculate_liquidity_index(7_776_000_u256);
    println!("-----3 months-----");
    let (scaled, balance, _) = compute_user_yield(liquidity_index);
    let expected = ray_mul(scaled, liquidity_index);
    assert(balance == expected, '3 months: balance_of failed');
}

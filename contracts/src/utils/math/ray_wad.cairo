use core::integer::{u512, u512_safe_div_rem_by_u256};
/// As Cairo does not support float this module
/// provides high-precision constants for financial math operations.
use core::num::traits::{Bounded, OverflowingSub, WideMul};
use starknet_hackathon::utils::math::u512_ops::u512_add_u256;

/// 1 * 10^18 (18 decimal places) — used for token amounts
pub const WAD: u256 = 1_000_000_000_000_000_000; // 1_u256.pow(18);
/// Half of WAD, used for rounding
pub const HALF_WAD: u256 = WAD / 2;
/// 1 * 10^27 (27 decimal places) — used for interest rates, indexes, etc.
pub const RAY: u256 = 1_000_000_000_000_000_000_000_000_000;// 1_u256.pow(27);
/// Half of RAY, used for rounding
pub const HALF_RAY: u256 = RAY / 2;

pub fn ray_mul(a: u256, b: u256) -> u256 {
    if b == 0_u256 {
        return 0_u256;
    }

    // Overflow check: a <= (MAX_U256 - HALF_RAY) / b
    let max_u256: u256 = Bounded::MAX;
    let (diff, overflow) = max_u256.overflowing_sub(HALF_RAY);
    assert(!overflow, 'Overflow: ray_mul');

    let max_safe_a = diff / b;
    assert(a <= max_safe_a, 'Overflow: ray_mul');

    // Safe wide multiplication
    let wide_mul: u512 = a.wide_mul(b);
    let wide_rounded = u512_add_u256(wide_mul, HALF_RAY);
    let non_zero_ray: NonZero<u256> = RAY.try_into().expect('RAY must be nonzero');

    let (quotient, _) = u512_safe_div_rem_by_u256(wide_rounded, non_zero_ray);

    quotient.try_into().expect('Overflow: ray_mul')
}


pub fn ray_div(a: u256, b: u256) -> u256 {
    assert(b != 0_u256, 'Division by zero');

    // Check for overflow
    let half_b: u256 = b / 2_u256;
    let max_u256: u256 = Bounded::MAX;
    let (diff, overflow) = max_u256.overflowing_sub(half_b);
    assert(!overflow, 'Overflow: ray_div');

    let max_safe_a: u256 = diff / RAY;
    assert(a <= max_safe_a, 'Overflow: ray_div');

    // Need to cast in wide unsigned to avoid overflow
    let wide_num: u512 = a.wide_mul(RAY);
    let wide_num_rounded = u512_add_u256(wide_num, half_b);
    let non_zero_b: NonZero<u256> = b.try_into().expect('b must be non-zero');
    let (quotient, _) = u512_safe_div_rem_by_u256(wide_num_rounded, non_zero_b);
    quotient.try_into().expect('Overflow: ray_div')
}

pub fn wad_mul(a: u256, b: u256) -> u256 {
    if b == 0_u256 {
        return 0_u256;
    }

    let max_u256: u256 = Bounded::MAX;
    let (diff, overflow) = max_u256.overflowing_sub(HALF_WAD);
    assert(!overflow, 'overflow: wad_mul');

    let max_safe_a = diff / b;
    assert(a <= max_safe_a, 'overflow: wad_mul');

    let wide_mul: u512 = a.wide_mul(b);
    let wide_rounded = u512_add_u256(wide_mul, HALF_WAD);
    let non_zero_wad: NonZero<u256> = WAD.try_into().expect('wad must be nonzero');

    let (quotient, _) = u512_safe_div_rem_by_u256(wide_rounded, non_zero_wad);
    quotient.try_into().expect('overflow: wad_mul')
}


pub fn wad_div(a: u256, b: u256) -> u256 {
    assert(b != 0_u256, 'division by zero');

    let half_b = b / 2_u256;
    let max_u256: u256 = Bounded::MAX;
    let (diff, overflow) = max_u256.overflowing_sub(half_b);
    assert(!overflow, 'overflow: wad_div');

    let max_safe_a = diff / WAD;
    assert(a <= max_safe_a, 'overflow: wad_div');

    let wide_num = a.wide_mul(WAD);
    let wide_rounded = u512_add_u256(wide_num, half_b);
    let non_zero_b = b.try_into().expect('b must be nonzero');

    let (quotient, _) = u512_safe_div_rem_by_u256(wide_rounded, non_zero_b);
    quotient.try_into().expect('overflow: wad_div')
}

pub fn wad_to_ray(wad: u256) -> u256 {
    let scale = RAY / WAD;

    // Overflow protection
    let max_u256: u256 = Bounded::MAX;
    let max_safe_wad = max_u256 / scale;
    assert(wad <= max_safe_wad, 'overflow: wad_to_ray');

    wad * scale
}

pub fn ray_to_wad(ray: u256) -> u256 {
    let ratio = RAY / WAD;
    let half_ratio = ratio / 2_u256;

    let wide_rounded = ray.wide_mul(half_ratio);
    let non_zero_ratio = ratio.try_into().unwrap();
    let (quotient, _) = u512_safe_div_rem_by_u256(wide_rounded, non_zero_ratio);
    quotient.try_into().unwrap()
}

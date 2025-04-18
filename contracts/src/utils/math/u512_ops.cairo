use core::integer::u512;
use core::num::traits::{OverflowingAdd, OverflowingSub};
use core::option::Option;

#[derive(Copy, Drop, Hash, PartialEq, Serde)]
struct u256X2 {
    low: u256,
    high: u256,
}

pub impl U512Intou256X2 of Into<u512, u256X2> {
    #[inline(always)]
    fn into(self: u512) -> u256X2 {
        let u512 { limb0: low, limb1: high, limb2, limb3 } = self;
        u256X2 { low: u256 { low, high }, high: u256 { low: limb2, high: limb3 } }
    }
}

pub impl U512TryIntoU256 of TryInto<u512, u256> {
    fn try_into(self: u512) -> Option<u256> {
        if self.limb2 != 0 || self.limb3 != 0 {
            Option::None
        } else {
            Option::Some(u256 { low: self.limb0, high: self.limb1 })
        }
    }
}

#[inline(always)]
pub fn u512_add(lhs: u512, rhs: u512) -> u512 {
    let lhs: u256X2 = lhs.into();
    let rhs: u256X2 = rhs.into();

    // No overflow allowed
    let (sum_high, overflow_high) = lhs.high.overflowing_add(rhs.high);
    assert(!overflow_high, 'u512 add overflow');

    let u256 { low: mut limb2, high: mut limb3 } = sum_high;
    // Addition des bas 256 bits (limb0 & limb1)
    let (sum_low, overflow_low) = lhs.low.overflowing_add(rhs.low);
    let u256 { low: limb0, high: limb1 } = sum_low;

    if overflow_low {
        let (new_limb2, carry) = limb2.overflowing_add(1_u128);
        limb2 = new_limb2;
        if carry {
            let (new_limb3, carry2) = limb3.overflowing_add(1_u128);
            assert(!carry2, 'u512 add overflow');
            limb3 = new_limb3;
        }
    }

    u512 { limb0, limb1, limb2, limb3 }
}

#[inline(always)]
pub fn u512_sub(lhs: u512, rhs: u512) -> u512 {
    let lhs: u256X2 = lhs.into();
    let rhs: u256X2 = rhs.into();

    let (mut limb2, borrow2) = lhs.high.low.overflowing_sub(rhs.high.low);
    let (mut limb3, borrow3) = lhs.high.high.overflowing_sub(rhs.high.high);

    if borrow2 {
        let (new_limb3, borrow) = limb3.overflowing_sub(1_u128);
        assert(!borrow, 'u512 sub overflow');
        limb3 = new_limb3;
    }

    let (limb0, borrow0) = lhs.low.low.overflowing_sub(rhs.low.low);
    let (mut limb1, borrow1) = lhs.low.high.overflowing_sub(rhs.low.high);

    if borrow0 {
        let (new_limb1, borrow) = limb1.overflowing_sub(1_u128);
        assert(!borrow, 'u512 sub overflow');
        limb1 = new_limb1;
    }

    u512 { limb0, limb1, limb2, limb3 }
}

#[inline(always)]
pub fn u512_add_u256(lhs: u512, rhs: u256) -> u512 {
    let u256X2 { high, low }: u256X2 = lhs.into();

    let u256 { high: mut limb3, low: mut limb2 } = high;

    // Addition bas 256 bits
    let (sum_low, overflow_low) = low.overflowing_add(rhs);
    let u256 { low: limb0, high: limb1 } = sum_low;

    if overflow_low {
        let (new_limb2, carry) = limb2.overflowing_add(1_u128);
        limb2 = new_limb2;

        if carry {
            let (new_limb3, carry2) = limb3.overflowing_add(1_u128);
            assert(!carry2, 'u512_add_u256 overflow');
            limb3 = new_limb3;
        }
    }

    u512 { limb0, limb1, limb2, limb3 }
}

#[inline(always)]
pub fn u512_sub_u256(lhs: u512, rhs: u256) -> u512 {
    let u256X2 { low: lhs_low, high: lhs_high } = lhs.into();
    let u256 { low: mut limb2, high: mut limb3 } = lhs_high;

    let (diff_low, borrow_low) = lhs_low.overflowing_sub(rhs);
    let u256 { low: limb0, high: limb1 } = diff_low;

    if borrow_low {
        let (new_limb2, borrow2) = limb2.overflowing_sub(1_u128);
        limb2 = new_limb2;
        if borrow2 {
            let (new_limb3, borrow3) = limb3.overflowing_sub(1_u128);
            assert(!borrow3, 'u512_sub_u256 overflow');
            limb3 = new_limb3;
        }
    }

    u512 { limb0, limb1, limb2, limb3 }
}

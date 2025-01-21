/// Module: apply_for_adoption
module lock_stake::lock_stake {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self, ID};
    use std::string::String;
    use std::vector;
    use sui::balance::{Balance, Self};
    use sui::table::{Self, Table, new};
    use sui::vec_map::{Self, VecMap};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui_system::staking_pool::StakedSui;
    use sui_system::sui_system::{Self, SuiSystemState};
    // use sui::balance::{Self, Balance};
    use std::option::{Option, Self, some, none, is_some, extract};
    use apply_for_adoption::apply_for_adoption::{AdoptContract,AdoptContracts};


    //==============================================================================================
    // Constants
    //==============================================================================================

    const EInsufficientBalance: u64 = 0;

    //==============================================================================================
    // Error codes
    //==============================================================================================

    //==============================================================================================
    // Structs
    //==============================================================================================

    /// 质押合同
    public struct LockedStake has key {
        id: UID,
        // key: adoptContractID
        staked_sui: VecMap<ID, StakedSui>,
        sui: Balance<SUI>,
    }

    /// 创建质押合同
    public fun new_locked_stake(locked_until_epoch: u64, ctx: &mut TxContext): LockedStake {
        LockedStake {
            id: object::new(ctx),
            staked_sui: vec_map::empty(),
            sui: balance::zero(),
        }
    }

    //==============================================================================================
    // Event Structs
    //==============================================================================================

    //==============================================================================================
    // Init
    //==============================================================================================

    //==============================================================================================
    // Entry Functions
    //==============================================================================================
    // todo 签署合同,生成质押
    /// 合同上锁
    public fun stake(
        ls: &mut LockedStake,
        sui_system: &mut SuiSystemState,
        amount: u64,
        validator_address: address,
        ctx: &mut TxContext,
    ) {
        assert!(balance::value(&ls.sui) >= amount, EInsufficientBalance);
        let stake = sui_system::request_add_stake_non_entry(
            sui_system,
            coin::from_balance(balance::split(&mut ls.sui, amount), ctx),
            validator_address,
            ctx,
        );
        deposit_staked_sui(ls, stake);
    }

    /// 上锁的质押合同存储到 map 中
    public fun deposit_staked_sui(ls: &mut LockedStake, staked_sui: StakedSui) {
        let id = object::id(&staked_sui);
        vec_map::insert(&mut ls.staked_sui, id, staked_sui);
    }

    /// 解锁质押合同，返回该返回的币
    public fun unstake(
        ls: &mut LockedStake,
        sui_system: &mut SuiSystemState,
        staked_sui_id: ID,
        ctx: &mut TxContext,
    ): u64 {
        // todo errorCode
        assert!(vec_map::contains(&ls.staked_sui, &staked_sui_id), 3);
        let (_, stake) = vec_map::remove(&mut ls.staked_sui, &staked_sui_id);
        // Sui 系统模块提供的函数，用于解质押并结算奖励。会将质押对象（StakedSui）转换为 SUI 余额，包括本金和累积的奖励
        let sui_balance = sui_system::request_withdraw_stake_non_entry(sui_system, stake, ctx);
        let amount = balance::value(&sui_balance);
        deposit_sui(ls, sui_balance);
        amount
    }


    //==============================================================================================
    // Getter Functions
    //==============================================================================================

    /// 从质押合约中获取
    public fun staked_sui(ls: &LockedStake): &VecMap<ID, StakedSui> {
        &ls.staked_sui
    }

    public fun sui_balance(ls: &LockedStake): u64 {
        balance::value(&ls.sui)
    }


    //==============================================================================================
    // Update Functions
    //==============================================================================================


    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



/// Module: apply_for_adoption
module apply_for_adoption::lock_stake {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{Self, ID};
    use sui_system::staking_pool::{StakedSui, StakingPool};


    //==============================================================================================
    // Constants
    //==============================================================================================


    //==============================================================================================
    // Error codes
    //==============================================================================================

    //==============================================================================================
    // Structs
    //==============================================================================================

    /// 质押合同
    public struct LockedStake has store {
        id: ID,
        // 质押合同
        staking_pool: StakingPool,
        staked_sui: StakedSui,
        // 平台地址
        platformAddress: address,
    }


    //==============================================================================================
    // Event Structs
    //==============================================================================================

    //==============================================================================================
    // Functions
    //==============================================================================================

    /// 用户-创建质押合同
    public fun new_locked_stake(staking_pool: StakingPool, staked_sui: StakedSui, ctx: &mut TxContext): LockedStake {
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        LockedStake {
            id,
            staking_pool,
            staked_sui,
            platformAddress: sui::tx_context::sender(ctx),
        }
    }

    //==============================================================================================
    // Getter/Setter Functions
    //==============================================================================================

    /// 获取LockedStake的ID
    public(package) fun get_id(ls: &LockedStake): ID {
        ls.id
    }

    /// 获取LockedStake的质押SUI
    public(package) fun get_staked_sui(ls: &LockedStake): StakedSui {
        ls.staked_sui
    }

    /// 获取LockedStake的质押SUI
    public(package) fun get_staking_pool(ls: &LockedStake): StakingPool {
        ls.staking_pool
    }

    /// 获取LockedStake的平台地址
    public(package) fun get_platform_address(ls: &LockedStake): address {
        ls.platformAddress
    }

    //==============================================================================================
    // Update Functions
    //==============================================================================================
    /// 通过解构删除
    public(package) fun destroy(old_ls: LockedStake): ID {
        let LockedStake {
            id: id,
            staking_pool,
            staked_sui,
            // 平台地址
            platformAddress: _
        } = old_ls;
        // 销毁staked_sui
        let StakedSui { id: staked_sui_uid, pool_id: _, stake_activation_epoch: _, principal: _ } = staked_sui;
        object::delete(staked_sui_uid);
        // 摧毁staking_pool
        let StakingPool {
            id: staking_pool_uid, activation_epoch: _, deactivation_epoch: _, rewards_pool: _,
            pool_token_balance: _,
            exchange_rates: _,
            pending_stake: _,
            pending_total_sui_withdraw: _,
            pending_pool_token_withdraw: _,
            extra_fields: _
        } = staking_pool;
        let staking_pool_uid = object::borrow_uid(&staking_pool_uid);
        object::delete(staking_pool_uid);
        id
    }

    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



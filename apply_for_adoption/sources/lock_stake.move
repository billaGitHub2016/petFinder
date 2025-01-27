/// Module: apply_for_adoption
module apply_for_adoption::lock_stake {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::balance::Balance;
    use sui::object::{Self, ID};
    use sui::sui::SUI;
    use sui_system::staking_pool::{StakedSui};
    use sui_system::sui_system::{Self, SuiSystemState, request_withdraw_stake_non_entry, request_add_stake_non_entry};


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
    public fun new_locked_stake(staked_sui: StakedSui, ctx: &mut TxContext): LockedStake {
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        LockedStake {
            id,
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

    /// 获取LockedStake的平台地址
    public(package) fun get_platform_address(ls: &LockedStake): address {
        ls.platformAddress
    }

    public(package) fun get_withdraw_balance(system_state: &mut SuiSystemState,
                                             ls: &LockedStake,
                                             ctx: &mut TxContext): Balance<SUI> {
        request_withdraw_stake_non_entry(system_state, ls.staked_sui, ctx)
    }
    //==============================================================================================
    // Update Functions
    //==============================================================================================
    /// 通过解构删除
    // public(package) fun destroy(old_ls: LockedStake, ctx: &mut TxContext): ID {
    //     let LockedStake {
    //         id: id,
    //         staked_sui,
    //         // 平台地址
    //         platformAddress: _
    //     } = old_ls;
    //     // 销毁staked_sui
    //     let StakedSui { id: staked_sui_uid, pool_id: _, stake_activation_epoch: _, principal } = staked_sui;
    //     // 通过转移销毁
    //     // transfer::public_transfer(principal, sui::tx_context::sender(ctx));
    //     object::delete(staked_sui_uid);
    //     id
    // }

    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



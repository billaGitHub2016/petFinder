/// Module: apply_for_adoption
module apply_for_adoption::lock_stake {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self, ID};
    use sui::balance::{Balance, Self};
    use sui::vec_map::{Self, VecMap};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui_system::staking_pool::StakedSui;
    use sui_system::sui_system::{Self, SuiSystemState, request_withdraw_stake_non_entry};
    use apply_for_adoption::apply_for_adoption::{AdoptContract, getContractStatus, getUnusualStatus,
        getContractRecordTimes, getContractAmount, getContracPlatFormAddress, setContracLockedStake
        , getContracAdopterAddress, getLackLockStakeExceptionStatus, getContracAuditPassTimes};
    use std::option::{none, Option,is_some};
    use std::string::String;


    //==============================================================================================
    // Constants
    //==============================================================================================
    /// 余额不足
    const EInsufficientBalance: u64 = 200;

    //==============================================================================================
    // Error codes
    //==============================================================================================

    //==============================================================================================
    // Structs
    //==============================================================================================

    /// 质押合同
    public struct LockedStake has store,drop,copy {
        id: ID,
        staked_sui: Option<StakedSui>,
        sui: Balance<SUI>,
        // 平台地址
        platformAddress: address,
    }

    /// 用户-创建质押合同
    public fun new_locked_stake(ctx: &mut TxContext): LockedStake {
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        LockedStake {
            id,
            staked_sui: option::none<StakedSui>(),
            sui: balance::zero(),
            platformAddress: sui::tx_context::sender(ctx),
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
        ls: LockedStake,
        sui_system: &mut SuiSystemState,
        // 平台地址
        platformAddress: address,
        ctx: &mut TxContext,
        // 合约信息
        contract: &mut AdoptContract,
    ) {
        // 合约押金
        let amount = getContractAmount(contract);
        // 校验用户余额是否足够
        assert!(balance::value(&ls.sui) >= amount, EInsufficientBalance);
        // 捐赠给平台金额，规则：平台获取部门=押金 /（合约需要记录的次数+1）
        let recordTimes = getContractRecordTimes(contract);
        let platformAmount = amount / (recordTimes + 1);
        // 拆分balance
        let platFormBalance = balance::split(&mut ls.sui, platformAmount);
        // 存储进平台
        let _ = store_to_target(&ls, platformAddress, balance::value(&platFormBalance));
        // 剩余的balance
        let contractBalance = balance::split(&mut ls.sui, amount - platformAmount);
        // 将剩余的balance 添加到 Sui 系统中
        sui_system::request_add_stake_non_entry(
            sui_system,
            coin::from_balance(contractBalance, ctx),
            platformAddress,
            ctx,
        );
        // 质押合同存储到领养合约中
        setContracLockedStake(contract, ls);
    }

    /// 平台-解锁质押合同，返回该返回的币
    public fun unstake(
        ls: &mut LockedStake,
        sui_system: &mut SuiSystemState,
        contract: &mut AdoptContract,
        // 是否全部退还
        isAll: bool,
        ctx: &mut TxContext,
    ): u64 {
        // 获取质押对象
        let stake = ls.staked_sui;
        assert!(is_some(&stake) , getLackLockStakeExceptionStatus());
        // Sui 系统模块提供的函数，用于解质押并结算奖励。会将质押对象（StakedSui）转换为 SUI 余额，包括本金和累积的奖励
        let sui_balance = request_withdraw_stake_non_entry(sui_system, some(stake), ctx);
        let status = getContractStatus(contract);
        let platformAddress = getContracPlatFormAddress(contract);
        // 押金与利息
        let amount = balance::value(&sui_balance);
        // 根据是否全部退还的条件，进行退还押金
        if (isAll) {
            // 退还押金与利息给用户
            store_to_target(ls, getContracAdopterAddress(con), amount)
        } else {
            // 退养状态
            if (getContractStatus(contract) == getUnusualStatus()) {
                // 退还比例：（质押期间的利息+本金） / （合约需要记录的次数+1）* 审核通过次数
                let recordTimes = getContractRecordTimes(contract);
                let auditPassTimes = getContracAuditPassTimes(contract);
                let adopterAmount = amount / (recordTimes + 1) * auditPassTimes;
                // 平台获取剩余的部分
                let platFormAmount = amount - adopterAmount;
                store_to_target(ls, platformAddress, platFormAmount);
                let adopterAddress = getContracAdopterAddress(contract);
                // 退还押金与利息给用户
                store_to_target(ls, adopterAddress, adopterAmount)
                // 异常状态
            } else if (status == getUnusualStatus()) {
                // 全数退还给平台
                store_to_target(ls, platformAddress, amount)
            } else {
                0
            }
        }
        // 前端通知用户
    }


    //==============================================================================================
    // Getter Functions
    //==============================================================================================
    public fun sui_balance(ls: &LockedStake): u64 {
        balance::value(&ls.sui)
    }

    // 存储到对应地址
    public fun store_to_target(ls: &LockedStake, targetAddress: address, amount: u64): u64 {
        let _ = balance::transfer(ls.sui, targetAddress, amount);
        amount
    }

    //==============================================================================================
    // Update Functions
    //==============================================================================================


    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



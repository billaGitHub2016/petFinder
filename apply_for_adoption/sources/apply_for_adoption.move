/// Module: apply_for_adoption
module apply_for_adoption::apply_for_adoption {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self, ID};
    use std::string::String;
    use std::vector::{Self, length, empty, push_back, borrow_mut};
    use sui::event;
    use std::option::{Option, Self, some, none, is_some, extract, destroy_some};
    use sui::balance::{Balance, value, split};
    use sui::coin::{Coin, Self};
    use sui::sui::SUI;
    use apply_for_adoption::lock_stake::{Self, LockedStake};
    use sui::clock::{Clock, Self};
    use sui::transfer;
    use apply_for_adoption::contract::{
        AdoptContract,
        get_contract_status,
        AdoptContracts,
        add_contract,
        set_contract_status,
        get_contract_records,
        get_contract_record_times,
        get_contract_amount,
        get_contrac_platform_address,
        set_contract_remark,
        get_contrac_adopter_address,
        get_contrac_audit_pass_times,
        get_record_audit_result,
        get_record_year_month,
        create_new_record,
        set_contrac_audit_pass_times,
        set_record_audit_result,
        get_contract_donate_amount,
        create_new_contract, check_user_is_unusual, set_contrac_locked_stake,
        get_contrac_locked_stake, get_contrac_locked_stake_id,
        Record, get_adopt_contracts_by_contract_id, remove_contract, get_adopt_contract, check_animal_is_adopted
    };
    use apply_for_adoption::lock_stake::{new_locked_stake, get_withdraw_balance, get_lock_stake_id};
    use sui_system::sui_system::{Self, SuiSystemState, request_withdraw_stake_non_entry, request_add_stake_non_entry};


    //==============================================================================================
    // Constants
    //==============================================================================================
    /// 0-未生效
    const NOT_YET_IN_FORCE: u8 = 0;
    /// 1-生效
    const IN_FORCE: u8 = 1;
    /// 2-完成（完成回访）
    const FINISH: u8 = 2;
    /// 3-放弃
    const GIVE_UP: u8 = 3;
    /// 4-异常
    const UNSUAL: u8 = 4;

    //==============================================================================================
    // Error codes
    //==============================================================================================
    /// 已被领养
    const ADOPTED_EXCEPTION: u64 = 100;
    /// 领养异常
    const UNSUAL_ERROR: u64 = 101;
    /// 操作地址错误
    const ERROR_ADDRESS: u64 = 102;
    /// 找不到合约
    const NOT_EXSIT_CONTRACT: u64 = 103;
    /// 重复上传
    const REPEAT_UPLOAD_EXCEPTION: u64 = 104;
    /// 审核异常
    const AUDIT_EXCEPTION: u64 = 105;
    /// 押金异常
    const CONTRACT_AMOUNT_EXCEPTION: u64 = 106;
    /// 回访次数异常
    const CONTRRACT_RECORD_TIMES_EXCEPTION: u64 = 107;
    /// 缺少质押合同
    const LACK_LOCK_STAKE_ERROR: u64 = 108;
    /// 合同已完成，不需要再上传
    const FINISH_STATUS_ERROR: u64 = 109;
    /// 合同已完成，不需要再上传
    const StakedSuiNotExsist: u64 = 110;
    /// 余额不足
    const E_SUFFICIENT_BALANCE: u64 = 111;
    /// 未知合约状态异常
    const UNKNOE_CONTRACT_STATUS_EXCEPTION: u64 = 112;


    //==============================================================================================
    // Event Structs
    //==============================================================================================
    /// 创建合约后通知
    public struct CreateAdoptContractEvent has copy, drop {
        xId: String,
        animalId: String,
        contractId: ID,
        status: u8,
    }

    //==============================================================================================
    // Entry Functions
    //==============================================================================================
    // 创建合约
    public entry fun create_adopt_contract(
        // 领养人的x账号，用于校验用户信息
        x_id: String,
        // 领养动物id
        animal_id: String,
        // 领养合约金额
        amount: u64,
        // 领养人链上地址(用于校验用户以及退还押金)
        adopter_address: address,
        // 合约记录
        contracts: &mut AdoptContracts,
        // 合约需要记录的次数
        record_times: u64,
        // 捐赠给平台的币
        donateAmount: u64,
        // 获取 transcation 需要的信息
        ctx: &mut TxContext,
    ) {
        // todo 怎么确认当前创建合约的人是平台不是其他人
        // 平台
        let owner = sui::tx_context::sender(ctx);
        // 校验合约押金应该>0
        assert!(amount > 0, CONTRACT_AMOUNT_EXCEPTION);
        // 校验回访次数应该 >0
        assert!(record_times > 0, CONTRRACT_RECORD_TIMES_EXCEPTION);
        // 校验动物没有被领养
        assert!(check_animal_is_adopted(contracts, animal_id), ADOPTED_EXCEPTION);
        // 校验用户没有领养状态异常
        assert!(check_user_is_unusual(contracts, x_id), UNSUAL_ERROR);
        // 创建新的合同
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        // 空回访记录
        let records = empty<Record>();
        // 合约状态：未生效
        let status = NOT_YET_IN_FORCE;
        let remark = b"".to_string();
        // 创建一个新的领养合约
        let new_contract = create_new_contract(id, x_id, animal_id, amount, records, adopter_address, owner, status,
            remark, record_times, donateAmount);
        // 放到合约记录中
        add_contract(contracts, new_contract, animal_id, x_id);
        // todo 通知前端生成
        event::emit(CreateAdoptContractEvent {
            xId: x_id,
            animalId: animal_id,
            contractId: id,
            status,
        });
        // 丢弃uid
        object::delete(uid);
    }

    /// 用户-签署合同并缴纳押金
    /// 添加合同时明确捐赠部分费用
    public fun sign_adopt_contract(contract_id: ID,
                                   adopt_contains: &mut AdoptContracts,
                                   coin: &mut Coin<SUI>,
                                   system_state: &mut SuiSystemState,
                                   validator_address: address,
                                   ctx: &mut TxContext) {
        // 校验合同是否存在
        let contract = get_adopt_contracts_by_contract_id(adopt_contains, contract_id);
        let status = get_contract_status(contract);
        // 领养人地址
        let adopter_address = get_contrac_adopter_address(contract);
        // 平台方地址
        let plat_form_address = get_contrac_platform_address(contract);
        // 校验合同是否是该用户可以签署的
        assert!(adopter_address == sui::tx_context::sender(ctx), ERROR_ADDRESS);
        // 校验合约应未被签署
        assert!(status == NOT_YET_IN_FORCE, ADOPTED_EXCEPTION);
        // coin 中获取余额
        let coin_balance = coin::balance_mut(coin);
        // 合约押金
        let amount = get_contract_amount(contract);
        // 捐赠给平台
        let donate_amount = get_contract_donate_amount(contract);
        // 质押合同所需要的金额
        let contract_amount = donate_amount + amount;
        // 校验用户余额是否足够（押金+捐赠金）
        assert!(value(coin_balance) >= contract_amount, E_SUFFICIENT_BALANCE);
        // 拆分出质押合同所需要的金额
        let balance = split(coin_balance, contract_amount);
        let sender = sui::tx_context::sender(ctx);
        // 捐赠 balance
        if (donate_amount > 0) {
            let plat_form_balance = split(&mut balance, donate_amount);
            // 存储进平台
            store_to_target(plat_form_balance, plat_form_address, ctx);
        };
        // 将剩余的balance 添加到 Sui 系统中,完成质押 stake()
        let staked_sui = request_add_stake_non_entry(
            system_state,
            coin::from_balance(balance, ctx),
            validator_address,
            ctx,
        );
        // 创建质押合同
        let locked_stake = new_locked_stake(staked_sui, ctx);
        // 质押合同存储到领养合约中
        set_contrac_locked_stake(adopt_contains, locked_stake, contract);
        // 更新合同状态
        set_contract_status(contract, IN_FORCE);
        // todo 通知前端
    }

    /// 平台-销毁未生效合约，非未生效合约会报错并中止
    public entry fun destory_adopt_contact(
        animal_id: String,
        x_id: String,
        adopt_contains: &mut AdoptContracts,
        ctx: &mut TxContext,
    ) {
        remove_contract(adopt_contains, animal_id, x_id, ctx);
        // todo 通知前端移除完成
    }

    ///平台-更新合约状态：放弃领养,并添加备注
    public entry fun abendon_adopt_contract(
        animal_id: String,
        x_id: String,
        contracts: &mut AdoptContracts,
        remark: String,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        // 获取合约
        let mut contract = get_adopt_contract(contracts, animal_id, x_id);
        update_adopt_contract_status(contract, remark, GIVE_UP, ctx);
        /// 退养后押金处理
        /// 用户退养后，平台可解锁质押合同，按比例退还押金与利息
        /// 退还比例：（质押期间的利息+本金）/ （合约需要记录的次数+1）* 审核通过次数
        let mut contract_ref = contract;
        let lock_stake = get_contrac_locked_stake(contracts, contract);

        unstake(system_state, lock_stake, contract_ref, false, ctx);
    }

    /// 平台-更新合约状态：异常，并添加备注
    /// 用户长时间不上传，平台可设置为异常状态
    public entry fun unusual_adopt_contract(
        animal_id: String,
        x_id: String,
        adopt_contains: &mut AdoptContracts,
        remark: String,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        // 获取合约
        let mut contract = get_adopt_contract(adopt_contains, animal_id, x_id);
        let mut contract_ref = contract;
        update_adopt_contract_status(contract, remark, UNSUAL, ctx);
        let contract_ref_ref = contract_ref;
        /// 异常状态押金处理：全数退还给平台
        let lock_stake = get_contrac_locked_stake(adopt_contains, contract_ref);
        unstake(system_state, lock_stake, contract_ref_ref, false, ctx, );
    }


    /// 用户-上传回访记录
    public fun upload_record(
        contract_id: ID,
        contains: &mut AdoptContracts,
        pic: String,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        // 获取合约,不存在会抛异常
        let contract = get_adopt_contracts_by_contract_id(contains, contract_id);
        // 合同状态
        let status = get_contract_status(contract);
        // 领养人地址
        let adopter_address = get_contrac_adopter_address(contract);
        // 校验合同是否是该用户可以签署的
        assert!(adopter_address == sui::tx_context::sender(ctx), ERROR_ADDRESS);
        // 校验合同是否已经完成回访
        assert!(status != FINISH, FINISH_STATUS_ERROR);
        // todo 检查能否获取当前年月
        let year_month = clock::timestamp_ms(clock) / 1000 / 60 / 60 / 24 / 30;
        // 获取合约上传记录
        let records = get_contract_records(contract);
        let record_length = length(records);
        // 获取最后一次上传记录
        let last_record = vector::borrow(records, record_length - 1);
        // 最后一次上传记录的结果
        let last_audit_result_option = get_record_audit_result(last_record);
        // 校验最后一次记录平台需要审核，最后一次记录没有审核，无法上传新的记录
        assert!(is_some(&last_audit_result_option), AUDIT_EXCEPTION);
        // 获取最后一次上传记录的年月
        let last_year_month = get_record_year_month(last_record);
        let last_audit_result = option::borrow<bool>(&last_audit_result_option);
        // 获取最后一次上传记录审批结果
        if (is_some(&last_audit_result_option) && *last_audit_result == true) {
            // 校验是否有重复上传
            assert!(year_month != last_year_month, REPEAT_UPLOAD_EXCEPTION);
        };
        let record = create_new_record(pic, year_month, clock);
        let records = get_contract_records(contract);
        // 上传回访记录
        push_back(records, record);
        // todo 通知前端有用户上传回访记录
    }

    // todo 平台-审核上传的回访记录
    public fun audit_record(contract_id: ID,
                            contracts: &mut AdoptContracts,
                            // 审核结果：true-通过；false-不通过
                            audit_result: bool,
                            // 审核备注
                            audit_remark: String,
                            system_state: &mut SuiSystemState,
                            ctx: &mut TxContext) {
        // 合约信息,不存在会直接抛异常
        let contract = get_adopt_contracts_by_contract_id(contracts, contract_id);
        // 获取合同状态
        let status = get_contract_status(contract);
        // 校验合约必须生效
        assert!(status == IN_FORCE, NOT_EXSIT_CONTRACT);
        // 获取平台地址
        let platform_address = get_contrac_platform_address(contract);
        // 校验当前用户是否是平台
        assert!(platform_address == sui::tx_context::sender(ctx), ERROR_ADDRESS);
        // 获取审核通过次数
        let mut audit_pass_times = get_contrac_audit_pass_times(contract);
        // 审核通过增加审核通过次数
        if (audit_result) {
            set_contrac_audit_pass_times(contract, audit_pass_times + 1);
            audit_pass_times = get_contrac_audit_pass_times(contract);
        };
        // 获取上传记录
        let records = get_contract_records(contract);
        // 获取记录次数
        let record_length = length(records);
        // 获取最后一次上传记录
        let last_record = borrow_mut(records, record_length - 1);
        // 更新回访记录备注
        set_contract_remark(contract, audit_remark);
        // 更新审核结果
        set_record_audit_result(last_record, option::some<bool>(audit_result));
        // 获取需要记录次数
        let record_times = get_contract_record_times(contract);
        // 校验合同审核通过次数是否等于需要记录次数
        if (audit_pass_times == record_times) {
            // 更新合同状态
            set_contract_status(contract, FINISH);
            let mut lock_stake = get_contrac_locked_stake(contracts, contract);
            // 退还押金与利息
            unstake(system_state, lock_stake, contract, true, ctx);
        };
        // todo 通知用户审核结果
    }

    //==============================================================================================
    // Getter/Setter Functions
    //==============================================================================================

    /// 获取异常状态值
    public fun get_unusual_status(): u8 {
        UNSUAL
    }

    /// 获取缺失质押合同异常状态
    public fun get_lack_lock_stake_exception_status(): u64 {
        LACK_LOCK_STAKE_ERROR
    }

    /// 获取异常状态值
    public fun get_in_force_status(): u8 {
        IN_FORCE
    }


    //==============================================================================================
    // Functions
    //==============================================================================================

    /// 平台-解锁质押合同，返回该返回的币
    public fun unstake(
        system_state: &mut SuiSystemState,
        lock_stake: &mut LockedStake,
        contract: &mut AdoptContract,
        // 是否全部退还
        is_all: bool,
        ctx: &mut TxContext,
    ) {
        // Sui 系统模块提供的函数，用于解质押并结算奖励。会将质押对象（StakedSui）转换为 SUI 余额，包括本金和累积的奖励
        let mut withdraw_balance = get_withdraw_balance(system_state, lock_stake, ctx);
        let status = get_contract_status(contract);
        let plat_form_address = get_contrac_platform_address(contract);
        // 押金与利息
        let withdraw_amount = value(&withdraw_balance);
        // 领养人账号
        let user_address = get_contrac_adopter_address(contract);
        // 根据是否全部退还的条件，进行退还押金
        if (is_all) {
            // 退还押金与利息给用户
            store_to_target(withdraw_balance, user_address, ctx)
        } else {
            // 退养状态
            if (get_contract_status(contract) == get_unusual_status()) {
                // 退还比例：（质押期间的利息+本金） / （合约需要记录的次数+1）* 审核通过次数
                let recordTimes = get_contract_record_times(contract);
                let auditPassTimes = get_contrac_audit_pass_times(contract);
                let adopterAmount = withdraw_amount / recordTimes * auditPassTimes;
                // 平台获取剩余的部分
                let plat_form_amount = withdraw_amount - adopterAmount;
                let plaf_form_balance = split(&mut withdraw_balance, plat_form_amount);
                store_to_target(plaf_form_balance, plat_form_address, ctx);
                // 领养人
                let adopter_address = get_contrac_adopter_address(contract);
                // 退还押金与利息给用户
                return store_to_target(withdraw_balance, adopter_address, ctx)
                // 异常状态或其他状态全数退还给平台
            };
            // else if (status == get_unusual_status()) {
            // 全数退还给平台
            store_to_target(withdraw_balance, plat_form_address, ctx)
            // }
        }
        // 前端通知用户
    }

    /// 存储到对应地址
    public fun store_to_target(balance: Balance<SUI>, targetAddress: address, ctx: &mut TxContext) {
        // balance 2 coin for transfer
        let coin = coin::from_balance(balance, ctx);
        transfer::public_transfer(coin, targetAddress);
    }

    //==============================================================================================
    // Update Functions
    //==============================================================================================
    fun update_adopt_contract_status(
        contract: &mut AdoptContract,
        remark: String,
        status: u8,
        ctx: &mut TxContext,
    ) {
        // 获取用户合约
        let owner = sui::tx_context::sender(ctx);
        // 获取合约中平台地址
        let plat_form_address = get_contrac_platform_address(contract);
        // 校验是否是创建者创建
        assert!(plat_form_address == owner, ERROR_ADDRESS);
        // 更新状态
        set_contract_status(contract, status);
        set_contract_remark(contract, remark);
        // todo 通知前端
    }

    //==============================================================================================
    // Helper Functions
    //==============================================================================================
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        apply_for_adoption::contract::init(ctx);
    }


    #[test_only]
    public fun get_contract(contracts: &mut AdoptContracts, animal_id: String, x_id: String): &mut AdoptContract {
        get_adopt_contract(contracts, animal_id, x_id)
    }
}



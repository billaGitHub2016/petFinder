/// Module: apply_for_adoption
module apply_for_adoption::apply_for_adoption {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self, ID};
    use std::string::String;
    use std::vector::{Self, length, borrow, empty, push_back, swap_remove, borrow_mut};
    use sui::event;
    use sui::table::{Self, Table};
    use std::option::{Option, Self, some, none, is_some, extract, borrow, destroy_some};
    use sui::balance::{Balance, value, split};
    use sui::coin::{Coin, Self};
    use sui::sui::SUI;
    use apply_for_adoption::lock_stake::{Self, LockedStake};
    use sui::clock::{Clock, Self};
    use sui::transfer;
    use apply_for_adoption::contract::{AdoptContract, get_contract_status, AdoptContracts, get_adopt_contracts,
        get_user_contract_table, getContractXId, get_lock_stake, set_contract_status, getContractID, get_contract_records,
        get_contract_record_times, getContractAmount, get_contrac_platform_address, set_contract_remark,
        get_contrac_adopter_address, get_contrac_audit_pass_times, get_animal_contract_table, get_record_audit_result,
        get_record_year_month, create_new_record, set_contrac_audit_pass_times, set_record_audit_result,
        get_contrac_animal_id,
        getContractDonateAmount, setContracLockedStake, create_new_contract, Record};
    use apply_for_adoption::lock_stake::{new_locked_stake, get_staked_sui, get_staking_pool};

    //==============================================================================================
    // Constants
    //==============================================================================================
    /// 0-未生效
    const NotYetInForce: u8 = 0;
    /// 1-生效
    const IN_FORCE: u8 = 1;
    /// 2-完成（完成回访）
    const Finish: u8 = 2;
    /// 3-放弃
    const GiveUp: u8 = 3;
    /// 4-异常
    const UNSUAL: u8 = 4;

    //==============================================================================================
    // Error codes
    //==============================================================================================
    /// 已被领养
    const AdoptedException: u64 = 100;
    /// 领养异常
    const UnsusalException: u64 = 101;
    /// 操作地址错误
    const ErrorAddress: u64 = 102;
    /// 找不到合约
    const NOT_EXSIT_CONTRACT: u64 = 103;
    /// 重复上传
    const REPEAT_UPLOAD_EXCEPTION: u64 = 104;
    /// 审核异常
    const AUDIT_EXCEPTION: u64 = 105;
    /// 押金异常
    const ContractAmountException: u64 = 106;
    /// 回访次数异常
    const ContractRecordTimesException: u64 = 107;
    /// 缺少质押合同
    const LackLockStakeException: u64 = 108;
    /// 合同已完成，不需要再上传
    const FinshStatus: u64 = 109;
    /// 合同已完成，不需要再上传
    const StakedSuiNotExsist: u64 = 110;
    /// 余额不足
    const EInsufficientBalance: u64 = 111;
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
        xId: String,
        // 领养动物id
        animalId: String,
        // 领养合约金额
        amount: u64,
        // 领养人链上地址(用于校验用户以及退还押金)
        adopterAddress: address,
        // 合约记录
        adoptContracts: &mut AdoptContracts,
        // 合约需要记录的次数
        recordTimes: u64,
        // 捐赠给平台的币
        donateAmount: u64,
        // 获取 transcation 需要的信息
        ctx: &mut TxContext,
    ) {
        // 获取动物合约集合
        let animalContractsTable = get_animal_contract_table(adoptContracts);
        // 获取用户合约集合
        let mut userContractsTable = get_user_contract_table(adoptContracts);
        // 获取合约集合
        let contractsTable = get_adopt_contracts(adoptContracts);
        // todo 怎么确认当前创建合约的人是平台不是其他人
        // 平台
        let owner = sui::tx_context::sender(ctx);
        // 校验合约押金应该>0
        assert!(amount > 0, ContractAmountException);
        // 校验回访次数应该 >0
        assert!(recordTimes > 0, ContractRecordTimesException);
        // 查询动物是否有被领养
        let animalContains = table::contains(&mut animalContractsTable, animalId);
        if (animalContains) {
            // 注意：不存在会报错
            let contractIds = table::borrow_mut(&mut animalContractsTable, animalId);
            let contractLenght = length(contractIds);
            let mut index = 0;
            while (contractLenght > index) {
                let contractId = borrow(contractIds, index);
                let contract = table::borrow(&mut contractsTable, contractId);
                let status = get_contract_status(contract);
                // 校验动物不存在生效或完成的合同
                assert!(status != IN_FORCE || status != Finish, AdoptedException);
                index = index + 1;
            };
        };
        let userContains = table::contains(userContractsTable, xId);
        if (userContains) {
            // 查询该用户是否有异常领养记录
            let contractIds = table::borrow(userContractsTable, xId);
            let contractlength = length(contractIds);
            let mut index = 0;
            while (contractlength > index) {
                let contractId = borrow(contractIds, index);
                let contract = table::borrow(&mut contractsTable, contractId);
                index = index + 1;
                let status = get_contract_status(contract);
                // 校验动物不存在异常状态
                assert!(status != UNSUAL, UnsusalException);
            };
        };
        // 创建新的合同
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        // 空回访记录
        let records = empty<Record>();
        // 合约状态：未生效
        let status = NotYetInForce;
        let remark = b"".to_string();
        // 创建一个新的领养合约
        let new_contract = create_new_contract(id, xId, animalId, amount, records, adopterAddress, owner, status,
            remark, recordTimes, donateAmount);
        // 放到合约记录中
        if (animalContains) {
            // 存在则直接添加
            let animalContracts = table::borrow_mut(&mut animalContractsTable, animalId);
            push_back(animalContracts, id);
        };
        if (userContains) {
            // 存在则直接添加
            let userContains = table::borrow_mut(userContractsTable, xId);
            push_back(userContains, id);
        };
        // 合同信息加入到合同列表中
        table::add(&mut contractsTable, id, new_contract);
        // todo 通知前端生成
        event::emit(CreateAdoptContractEvent {
            xId,
            animalId,
            contractId: id,
            status,
        });
        // 丢弃uid
        object::delete(uid);
    }

    /// 用户-签署合同并缴纳押金
    // todo 变更平台抽成获取日常运营费用逻辑：添加合同时明确捐赠部分费用，可为0
    public fun sign_adopt_contract(adoptContractID: ID,
                                   adoptContains: &mut AdoptContracts,
                                   coin: &mut Coin<SUI>,
                                   ctx: &mut TxContext) {
        // 获取合约集合
        let contractsTable = get_adopt_contracts(adoptContains);
        // 校验合同是否存在
        let contract = table::borrow_mut(&mut contractsTable, adoptContractID);
        let status = get_contract_status(contract);
        // 领养人地址
        let adopterAddress = get_contrac_adopter_address(contract);
        // 平台方地址
        let plat_form_address = get_contrac_platform_address(contract);
        // 校验合同是否是该用户可以签署的
        assert!(adopterAddress == sui::tx_context::sender(ctx), ErrorAddress);
        // 校验合约应未被签署
        assert!(status == NotYetInForce, AdoptedException);
        // coin 中获取余额
        let coin_balance = coin::balance_mut(coin);
        // 合约押金
        let amount = getContractAmount(contract);
        // 捐赠给平台
        let donate_amount = getContractDonateAmount(contract);
        // 质押合同所需要的金额
        let contract_amount = donate_amount + amount;
        // 校验用户余额是否足够（押金+捐赠金）
        assert!(value(coin_balance) >= contract_amount, EInsufficientBalance);
        // 拆分出质押合同所需要的金额
        let balance = split(coin_balance, contract_amount);
        let sender = sui::tx_context::sender(ctx);
        // 捐赠 balance
        if (donate_amount > 0) {
            let platFormBalance = split(&mut balance, donate_amount);
            // 存储进平台
            store_to_target(platFormBalance, plat_form_address, ctx);
        };
        // 将剩余的balance 添加到 Sui 系统中
        // let staked_sui = request_add_stake_non_entry(
        //     sui_system,
        //     coin::from_balance(balance, ctx),
        //     sender,
        //     ctx,
        // );
        // staking_pool 完成质押
        let staking_pool = sui_system::staking_pool::new(ctx);
        let staked_sui =
            sui_system::staking_pool::request_add_stake(&mut staking_pool, balance, sui::tx_context::epoch(ctx), ctx);
        // 创建质押合同
        let ls = new_locked_stake(staking_pool, staked_sui, ctx);
        // 质押合同存储到领养合约中
        setContracLockedStake(contract, ls);
        // 更新合同状态
        set_contract_status(contract, IN_FORCE);
        // todo 通知前端
    }

    /// 平台-销毁未生效合约，非未生效合约会报错并中止
    public entry fun destory_adopt_contact(
        animalId: String,
        xId: String,
        adoptContains: &mut AdoptContracts,
        ctx: &mut TxContext,
    ) {
        // 获取动物合约集合
        let animalContractsTable = get_animal_contract_table(adoptContains);
        // 获取用户合约集合
        let userContractsTable = get_user_contract_table(adoptContains);
        // 获取合约集合
        let contractsTable = get_adopt_contracts(adoptContains);
        // 从合约中找到对应的合约,并移除
        // 从动物合约list 中移除该用户的合约
        if (table::contains( userContractsTable, xId)) {
            let userContracts = table::borrow_mut( userContractsTable, xId);
            // 找到对应的合同
            let (contract, index) =
                get_adopt_contract(userContracts, &mut contractsTable, animalId);
            let owner = sui::tx_context::sender(ctx);
            // 获取合约平台地址
            let platFormAddress = get_contrac_platform_address(&contract);
            // 校验是否是创建者创建
            assert!(platFormAddress == owner, ErrorAddress);
            // 移除合约
            let removeContractId = swap_remove(userContracts, index);
            //  删除合约
            let _ = table::remove(&mut contractsTable, removeContractId);
        };
        // 从用户合约list 中移除该动物的合约
        if (table::contains(&mut animalContractsTable, animalId)) {
            let adoptContracts = table::borrow_mut(&mut animalContractsTable, animalId);
            // 找到对应的用户
            let mut index = 0;
            let mut contractslength = length(adoptContracts);

            while (contractslength > index) {
                let contractId = borrow(adoptContracts, index);
                let contract = table::borrow(&mut contractsTable, contractId);
                let contractXId = getContractXId(contract);
                if (contractXId == xId) {
                    // 移除合约
                    let _ = swap_remove(adoptContracts, index);
                    break
                };
                index = index + 1;
            };
        };
        // todo 通知前端移除完成
    }

    ///平台-更新合约状态：放弃领养,并添加备注
    public entry fun abendon_adopt_contract(
        animalId: String,
        xId: String,
        adoptContains: &mut AdoptContracts,
        remark: String,
        ctx: &mut TxContext,
    ) {
        // 获取合约集合
        let contractsTable = get_adopt_contracts(adoptContains);
        let contract = update_adopt_contract_status(animalId, xId, adoptContains, remark, GiveUp, ctx);
        let adoptContractID = getContractID(&contract);
        let adoptContract = table::borrow_mut(&mut contractsTable, adoptContractID);
        /// 退养后押金处理
        /// 用户退养后，平台可解锁质押合同，按比例退还押金与利息
        /// 退还比例：（质押期间的利息+本金）/ （合约需要记录的次数+1）* 审核通过次数
        let lock_stake = get_lock_stake(adoptContract);
        let sui_system = get_staked_sui(lock_stake);
        unstake(lock_stake, adoptContract, false, ctx);
    }

    /// 平台-更新合约状态：异常，并添加备注
    /// 用户长时间不上传，平台可设置为异常状态
    public entry fun unusual_adopt_contract(
        animal_id: String,
        x_id: String,
        adopt_contains: &mut AdoptContracts,
        remark: String,
        ctx: &mut TxContext,
    ) {
        let contract = update_adopt_contract_status(animal_id, x_id, adopt_contains, remark, UNSUAL, ctx);
        /// 异常状态押金处理：全数退还给平台
        let lock_stake = get_lock_stake(&mut contract);
        let sui_system = get_staked_sui(lock_stake);
        unstake(lock_stake, &mut contract, false, ctx, );
    }


    /// 用户-上传回访记录
    public fun upload_record(
        adopt_contract_id: ID,
        adopt_contains: &mut AdoptContracts,
        pic: String,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        // 获取合约集合
        let contracts_table = get_adopt_contracts(adopt_contains);
        // 校验合同是否存在
        assert!(table::contains(&mut contracts_table, adopt_contract_id), NOT_EXSIT_CONTRACT);
        let contract = table::borrow_mut(&mut contracts_table, adopt_contract_id);
        // 合同状态
        let status = get_contract_status(contract);
        // 领养人地址
        let adopter_address = get_contrac_adopter_address(contract);
        // 校验合同是否是该用户可以签署的
        assert!(adopter_address == sui::tx_context::sender(ctx), ErrorAddress);
        // 校验合同是否已经完成回访
        assert!(status != Finish, FinshStatus);
        // todo 检查能否获取当前年月
        let year_month = clock::timestamp_ms(clock) / 1000 / 60 / 60 / 24 / 30;
        // 获取合约上传记录
        let records = get_contract_records(contract);
        let record_length = length(records);
        // 获取最后一次上传记录
        let last_record = borrow(records, record_length - 1);
        // 最后一次上传记录的结果
        let last_audit_result_option = get_record_audit_result(last_record);
        // 校验最后一次记录平台需要审核，最后一次记录没有审核，无法上传新的记录
        assert!(is_some(&last_audit_result_option), AUDIT_EXCEPTION);
        // 获取最后一次上传记录的年月
        let last_year_month = get_record_year_month(last_record);
        let last_audit_result = borrow<bool>(&mut last_audit_result_option);
        // 获取最后一次上传记录审批结果
        if (is_some(&last_audit_result_option) && last_audit_result == true) {
            // 校验是否有重复上传
            assert!(year_month != last_year_month, REPEAT_UPLOAD_EXCEPTION);
        };
        let record = create_new_record(pic);
        let records = get_contract_records(contract);
        // 上传回访记录
        push_back(records, record);
        // todo 通知前端有用户上传回访记录
    }

    // todo 平台-审核上传的回访记录
    public fun audit_record(contract_id: ID,
                            adopt_contracts: &mut AdoptContracts,
                            // 审核结果：true-通过；false-不通过
                            audit_result: bool,
                            // 审核备注
                            audit_remark: String,
                            ctx: &mut TxContext) {
        // 获取合约集合
        let contracts_table = get_adopt_contracts(adopt_contracts);
        // 校验合同是否存在
        assert!(table::contains(&contracts_table, contract_id));
        // 合约信息
        let contract = table::borrow_mut(&mut contracts_table, contract_id);
        // 获取合同状态
        let status = get_contract_status(contract);
        // 校验合约必须生效
        assert!(status == IN_FORCE, NOT_EXSIT_CONTRACT);
        // 获取平台地址
        let platform_address = get_contrac_platform_address(contract);
        // 校验当前用户是否是平台
        assert!(platform_address == sui::tx_context::sender(ctx), ErrorAddress);
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
            set_contract_status(contract, Finish);
            let lock_stake = get_lock_stake(contract);
            let sui_system = get_staked_sui(lock_stake);
            // 退还押金与利息
            unstake(lock_stake, contract, true, ctx);
        };
        // todo 通知用户审核结果
    }

    //==============================================================================================
    // Getter/Setter Functions
    //==============================================================================================
    /// 在用户领养的合约种根据动物id找到对应的合同
    fun get_adopt_contract(
        contract_ids: &mut vector<ID>,
        contracts: &mut Table<ID, AdoptContract>,
        animal_id: String
    ): (AdoptContract, u64) {
        let mut index = 0;
        let contracts_length = length(contract_ids);
        let result_contract;
        // 是否存在合约
        let sign = false;
        while (contracts_length > index) {
            let contract_id = borrow_mut(contract_ids, index);
            let copy_contract_id = *contract_id;
            let contract = table::remove(contracts, copy_contract_id);
            let contract_animal_id = get_contrac_animal_id(&contract);
            if (contract_animal_id == animal_id) {
                result_contract = contract;
                sign = true;
                break;
            } else {
                index = index + 1;
                continue
            }
        };
        assert!(sign, NOT_EXSIT_CONTRACT);
        return (result_contract, index)
    }

    /// 获取异常状态值
    public fun get_unusual_status(): u8 {
        UNSUAL
    }

    /// 获取缺失质押合同异常状态
    public fun get_lack_lock_stake_exception_status(): u64 {
        LackLockStakeException
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
        lock_stake: &mut LockedStake,
        contract: &mut AdoptContract,
        // 是否全部退还
        is_all: bool,
        ctx: &mut TxContext,
    ) {
        // 获取质押对象
        let stake_sui = get_staked_sui(lock_stake);
        let staking_pool = get_staking_pool(lock_stake);
        // Sui 系统模块提供的函数，用于解质押并结算奖励。会将质押对象（StakedSui）转换为 SUI 余额，包括本金和累积的奖励
        let mut withdraw_balance = sui_system::staking_pool::request_withdraw_stake(&mut staking_pool, stake_sui, ctx);
        let status = get_contract_status(contract);
        let plat_form_address = get_contrac_platform_address(contract);
        // 押金与利息
        let withdraw_amount = value(&withdraw_balance);
        // 领养人账号
        let user_address = get_contrac_adopter_address(contract);
        // 根据是否全部退还的条件，进行退还押金
        if (is_all) {
            // 退还押金与利息给用户
            store_to_target(withdraw_balance, user_address, ctx);
        } else {
            // 退养状态
            if (get_contract_status(contract) == get_unusual_status()) {
                // 退还比例：（质押期间的利息+本金） / （合约需要记录的次数+1）* 审核通过次数
                let recordTimes = get_contract_record_times(contract);
                let auditPassTimes = get_contrac_audit_pass_times(contract);
                let adopterAmount = withdraw_amount / recordTimes * auditPassTimes;
                // 平台获取剩余的部分
                let platFormAmount = withdraw_amount - adopterAmount;
                let plafFormBalance = split(&mut withdraw_balance, platFormAmount);
                store_to_target(plafFormBalance, plat_form_address, ctx);
                // 领养人
                let adopter_address = get_contrac_adopter_address(contract);
                // 退还押金与利息给用户
                store_to_target(withdraw_balance, adopter_address, ctx)
                // 异常状态
            } else if (status == get_unusual_status()) {
                // 全数退还给平台
                store_to_target(withdraw_balance, plat_form_address, ctx)
            } else {
                assert!(false, UNKNOE_CONTRACT_STATUS_EXCEPTION);
            }
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
        animalId: String,
        xId: String,
        adopt_contains: &mut AdoptContracts,
        remark: String,
        status: u8,
        ctx: &mut TxContext,
    ): AdoptContract {
        // 获取用户合约
        let userContractsTable = get_user_contract_table(adopt_contains);
        // 校验合同是否存在
        assert!(!table::contains( userContractsTable, xId));
        let userContracts = table::borrow_mut(userContractsTable, xId);
        let contracts = get_adopt_contracts(adopt_contains);
        // 找到对应的合同
        let (contract, _) = get_adopt_contract(userContracts, &mut contracts, animalId);
        let owner = sui::tx_context::sender(ctx);
        // 获取合约中平台地址
        let platFormAddress = get_contrac_platform_address(&contract);
        // 校验是否是创建者创建
        assert!(platFormAddress == owner, ErrorAddress);
        // 更新状态
        set_contract_status(&contract, status);
        set_contract_remark(&mut contract, remark);
        // todo 通知前端
        contract
    }

    //==============================================================================================
    // Helper Functions
    //==============================================================================================
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        apply_for_adoption::contract::init(ctx);
    }


    #[test_only]
    public fun get_contract(contracts: &mut AdoptContracts, animalId: String, xId: String): AdoptContract {
        // 获取用户合约
        let user_contracts_table = get_user_contract_table(contracts);
        assert!(table::contains(user_contracts_table, xId), NOT_EXSIT_CONTRACT);
        let contractIds = table::borrow_mut(user_contracts_table, xId);
        // 获取合约集合
        let mut contractsTable = get_adopt_contracts(adoptContains);
        let (contract, _) = get_adopt_contract(contractIds, &mut contractsTable, animalId);
        contract
    }
}



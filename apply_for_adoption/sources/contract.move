/// Module: apply_for_adoption
module apply_for_adoption::contract {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self, ID};
    use std::string::{String, utf8};
    use std::vector::{Self, length};
    use sui::clock::{Clock, Self};
    use sui::table::{Self, Table, new};
    use sui::transfer;
    use std::option::{Option, Self, some, none, is_some, extract, borrow};
    use apply_for_adoption::lock_stake::{Self, LockedStake, get_lock_stake_id};
    use sui::dynamic_field::{Self};

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
    const UnsusalException: u64 = 101;
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
    const FinshStatus: u64 = 109;
    /// 合同已完成，不需要再上传
    const StakedSuiNotExsist: u64 = 110;
    /// 余额不足
    const E_SUFFICIENT_BALANCE: u64 = 111;
    /// 未知合约状态异常
    const UNKNOE_CONTRACT_STATUS_EXCEPTION: u64 = 112;
    //==============================================================================================
    // Structs
    //==============================================================================================

    /// 领养合约 平台生成，owner 是平台
    public struct AdoptContract has store, drop {
        id: ID,
        // 领养用户xid
        xId: String,
        // 领养动物id
        animalId: String,
        // 领养花费币 <T>
        amount: u64,
        // 回访记录
        records: vector<Record>,
        // 领养人链上地址（用于交退押金）,指定领养人，避免被其他人领养
        adopterAddress: address,
        // 平台地址
        platFormAddress: address,
        // 合约状态：0-未生效；1-生效；2-完成（完成回访）；3-放弃；4-异常
        status: u8,
        // 备注
        remark: String,
        // todo 规定传记录次数
        recordTimes: u64,
        // 质押合同
        locked_stake_id: Option<ID>,
        // 审核通过次数
        auditPassTimes: u64,
        // 捐赠给平台的币
        donateAmount: u64,
    }

    // 回访记录
    public struct Record has store, drop {
        // 宠物图片
        pic: String,
        // 记录日期
        date: u64,
        // 年月记录上传图片的日期
        yearMonth: u64,
        // 审核结果：true-通过；false-不通过
        auditResult: Option<bool>,
        // 审核备注
        auditRemark: String,
    }

    // 动物信息
    public struct Animal has key, store {
        id: UID,
        // 姓名
        name: String,
        // 品种
        species: String,
        // 图片
        pic: String,
    }

    /// 所有的领养合约，包含未生效、生效、完成、弃养的合约
    /// 一个动物id可能会有多个合约的情况，也需要允许这种情况存在
    public struct AdoptContracts has key {
        id: UID,
        // key:animalId value:vector<ID> 动物id，合约
        animal_contracts: Table<String, vector<ID>>,
        // key:xId value:vector<ID> x用户id，合约
        user_contracts: Table<String, vector<ID>>,
        contracts: Table<ID, AdoptContract>,
    }

    //==============================================================================================
    // Init
    //==============================================================================================
    fun init(ctx: &mut TxContext) {
        // 公共浏览所有的合约
        transfer::share_object(AdoptContracts {
            id: object::new(ctx),
            animal_contracts: table::new<String, vector<ID>>(ctx),
            user_contracts: table::new<String, vector<ID>>(ctx),
            contracts: table::new<ID, AdoptContract>(ctx),
        });
        // todo 添加平台地址，避免其他人生成合同
    }

    //==============================================================================================
    // Functions
    //==============================================================================================
    /// 创建新的记录
    public(package) fun create_new_record(pic: String, year_month: u64, clock: &Clock): Record {
        Record {
            pic,
            date: clock::timestamp_ms(clock),
            yearMonth: year_month,
            auditResult: none(),
            auditRemark: b"".to_string(),
        }
    }

    public(package) fun create_new_contract(id: ID, xId: String, animalId: String,
                                            amount: u64, records: vector<Record>,
                                            adopterAddress: address, owner: address, status: u8,
                                            remark: String, recordTimes: u64, donateAmount: u64): AdoptContract {
        AdoptContract {
            id: id, // TODO id应该是object::new(ctx)这样创建的
            // 领养用户xid
            xId,
            // 领养动物id
            animalId,
            // 领养花费币 <SUI>
            amount,
            // 回访记录
            records,
            // 领养人链上地址（用于交退押金）,指定领养人，避免被其他人领养
            adopterAddress,
            // 平台地址
            platFormAddress: owner,
            // 合约状态：0-未生效；1-生效；2-完成（完成回访）；3-放弃；4-异常
            status,
            // 备注
            remark,
            // 合约需要记录的次数
            recordTimes,
            // 质押合同
            locked_stake_id: none(),
            // 审核通过次数
            auditPassTimes: 0,
            // 捐赠给平台的币
            donateAmount,
        }
    }

    /// 根据ID移除合约集的动物合约
    public(package) fun remove_contract(
        adopt_contracts: &mut AdoptContracts,
        animal_id: String,
        x_id: String,
        ctx: &mut TxContext,
    ) {
        // 找到对应的合同
        let contract = get_adopt_contract(adopt_contracts, animal_id, x_id);
        let contract_id = contract.id;
        let owner = sui::tx_context::sender(ctx);
        // 获取合约平台地址
        let plat_form_address = contract.platFormAddress;
        // 校验是否是平台创建的
        assert!(plat_form_address == owner, ERROR_ADDRESS);
        // 移除用户合约
        let mut user_contract_ids = table::borrow_mut(&mut adopt_contracts.user_contracts, x_id);
        let (user_contains, user_index) = vector::index_of(user_contract_ids, &contract_id);
        assert!(user_contains, NOT_EXSIT_CONTRACT);
        let remove_contract_id = vector::swap_remove(user_contract_ids, user_index);
        // 移除动物合约
        let mut animal_contract_ids = table::borrow_mut(&mut adopt_contracts.animal_contracts, animal_id);
        let (animal_contains, animal_index) = vector::index_of(user_contract_ids, &contract_id);
        assert!(animal_contains, NOT_EXSIT_CONTRACT);
        let _ = vector::swap_remove(animal_contract_ids, animal_index);
        //  删除合约
        let _ = table::remove(&mut adopt_contracts.contracts, remove_contract_id);
    }

    /// 添加合约
    public(package) fun add_contract(contracts: &mut AdoptContracts, contract: AdoptContract
                                     , animal_id: String, x_id: String) {
        // 添加用户合约
        add_contract_id(&mut contracts.user_contracts, x_id, contract.id);
        // 添加动物合约
        add_contract_id(&mut contracts.animal_contracts, animal_id, contract.id);
        // 合同信息加入到合同列表中
        table::add(&mut contracts.contracts, contract.id, contract);
    }

    /// 添加合约id到对应的table中
    fun add_contract_id(table: &mut Table<String, vector<ID>>, key: String, id: ID) {
        let is_contract_contains = table::contains(table, key);
        if (is_contract_contains) {
            // 存在则直接添加
            let mut contract_ids = table::borrow_mut(table, key);
            vector::push_back(contract_ids, id);
        } else {
            let mut contract_ids = vector::empty<ID>();
            vector::push_back(&mut contract_ids, id);
            table::add(table, key, contract_ids);
        };
    }


    /// 查询动物是否有被领养
    public(package) fun check_animal_is_adopted(contracts: &mut AdoptContracts, animal_id: String): bool {
        let mut contracts_ref = contracts;
        let mut animal_contracts_ref = &contracts.animal_contracts;
        let is_animal_contains_contract = table::contains(&contracts.animal_contracts, animal_id);
        if (is_animal_contains_contract) {
            // 注意：不存在会报错
            let contract_ids = table::borrow(animal_contracts_ref, animal_id);
            let contract_lenght = length(contract_ids);
            let mut index = 0;
            let mut is_adopted = false;
            while (contract_lenght > index) {
                let contract_id = vector::borrow(contract_ids, index);
                let contract_id_entry = *contract_id;
                let mut contract = get_adopt_contracts_by_contract_id(contracts_ref, contract_id_entry);
                let status = get_contract_status(contract);
                // 校验动物不存在生效或完成的合同
                if (status != IN_FORCE || status != FINISH) {
                    index = index + 1;
                } else {
                    is_adopted = true;
                    break;
                }
            };
            is_adopted
        } else {
            is_animal_contains_contract
        }
    }

    /// 查询该用户是否有异常领养记录
    public(package) fun check_user_is_unusual(contracts: &mut AdoptContracts, x_id: String): bool {
        let mut contracts_ref = contracts;
        let mut contracts_ref_ref = contracts_ref;
        let mut contracts_ref_ref_ref = contracts_ref_ref;
        let mut user_contracts_ref = &contracts_ref.user_contracts;
        let is_user_contains_contract = table::contains(&contracts_ref_ref.user_contracts, x_id);
        if (is_user_contains_contract) {
            let contract_ids = table::borrow(user_contracts_ref, x_id);
            let contract_length = length(contract_ids);
            let mut index = 0;
            let mut is_unusual = false;
            while (contract_length > index) {
                let contract_id = vector::borrow(contract_ids, index);
                let contract_id_entry = *contract_id;
                let mut contract = get_adopt_contracts_by_contract_id(contracts_ref_ref_ref, contract_id_entry);
                index = index + 1;
                let status = get_contract_status(contract);
                // 校验动物不存在异常状态
                if (status != UNSUAL) {
                    index = index + 1;
                } else {
                    is_unusual = true
                };
            };
            is_unusual
        } else {
            is_user_contains_contract
        }
    }
    //==============================================================================================
    // Getter/Setter Functions
    //==============================================================================================

    // -----------------------------------------AdoptContract-----------------------------------------
    /// 获取合约的动物id
    public fun get_contrac_animal_id(contract: &AdoptContract): String {
        contract.animalId
    }

    /// 获取合约的状态
    public fun get_contract_status(contract: &AdoptContract): u8 {
        contract.status
    }

    /// 设置合约的状态
    public fun set_contract_status(contract: &mut AdoptContract, status: u8) {
        contract.status = status
    }

    /// 获取合约的押金数量
    public(package) fun get_contract_amount(contract: &AdoptContract): u64 {
        contract.amount
    }

    /// 获取合约的捐赠数量
    public(package) fun get_contract_donate_amount(contract: &AdoptContract): u64 {
        contract.donateAmount
    }

    /// 获取合约的押金数量
    public(package) fun get_contract_record_times(contract: &AdoptContract): u64 {
        contract.recordTimes
    }


    /// 获取合约的领养用户地址
    public(package) fun get_contrac_adopter_address(contract: &AdoptContract): address {
        contract.adopterAddress
    }

    /// 获取合约的平台地址
    public(package) fun get_contrac_platform_address(contract: &AdoptContract): address {
        contract.platFormAddress
    }

    /// 获取合约的审核通过次数
    public(package) fun get_contrac_audit_pass_times(contract: &AdoptContract): u64 {
        contract.auditPassTimes
    }

    /// 设置合约的审核通过次数
    public(package) fun set_contrac_audit_pass_times(contract: &mut AdoptContract, times: u64) {
        contract.auditPassTimes = times
    }

    /// 获取合约的id
    public(package) fun get_contrac_id(contract: &AdoptContract): ID {
        contract.id
    }

    /// 获取合约的备注
    public(package) fun getContractRemark(contract: &AdoptContract): String {
        contract.remark
    }

    /// 设置合约的备注
    public(package) fun set_contract_remark(contract: &mut AdoptContract, remark: String) {
        contract.remark = remark
    }

    /// 获取合约的回访记录
    public(package) fun get_contract_records(contract: &mut AdoptContract): &mut vector<Record> {
        &mut contract.records
    }

    /// 获取合约的用户id
    public(package) fun get_contract_x_id(contract: &AdoptContract): String {
        contract.xId
    }

    /// 获取合约ID
    public(package) fun getContractID(contract: &AdoptContract): ID {
        contract.id
    }

    public(package) fun set_contrac_locked_stake(
        contracts: &mut AdoptContracts,
        locked_stake: LockedStake,
        contract: &mut AdoptContract
    ) {
        let locked_stake_id = get_lock_stake_id(&locked_stake);
        // 动态字段增加质押合约
        dynamic_field::add<ID, LockedStake>(&mut contracts.id, locked_stake_id, locked_stake);
        // 领养合同增加质押合同id
        contract.locked_stake_id = some(locked_stake_id);
    }

    /// 获取合约的质押合同
    public(package) fun get_contrac_locked_stake(
        contracts: &mut AdoptContracts,
        contract: &mut AdoptContract
    ): &mut  LockedStake {
        let locked_stake_id = option::borrow_mut(&mut contract.locked_stake_id);
        dynamic_field::borrow_mut<ID, LockedStake>(&mut contracts.id, *locked_stake_id)
    }

    /// 获取合约的质押合同ID
    public(package) fun get_contrac_locked_stake_id(contract: &mut AdoptContract): &mut ID {
        option::borrow_mut(&mut contract.locked_stake_id)
    }

    // ----------------------------------------AdoptContract-----------------------------------------
    // -----------------------------------------AdoptContracts-----------------------------------------
    /// 获取合约集合的合约
    public(package) fun get_adopt_contracts_by_contract_id(
        adopt_contracts: &mut AdoptContracts,
        id: ID
    ): &mut AdoptContract {
        table::borrow_mut(&mut adopt_contracts.contracts, id)
    }

    /// 在用户领养的合约中找到合同
    public(package) fun get_adopt_contract(
        contracts: &mut AdoptContracts,
        animal_id: String,
        x_id: String
    ): &mut AdoptContract {
        // 校验合同是否存在
        assert!(table::contains(&contracts.animal_contracts, animal_id), NOT_EXSIT_CONTRACT);
        assert!(table::contains(&contracts.user_contracts, x_id), NOT_EXSIT_CONTRACT);
        // 从动物id中找到合约
        let animal_contract_ids = table::borrow_mut(&mut contracts.animal_contracts, animal_id);
        let mut index = 0;
        let contracts_length = length(animal_contract_ids);
        // 是否存在合约
        let mut sign = false;
        let mut contract_id = vector::borrow_mut(animal_contract_ids, index);
        while (contracts_length > index) {
            contract_id = vector::borrow_mut(animal_contract_ids, index);
            let copy_contract_id = *contract_id;
            let contract = table::borrow_mut(&mut contracts.contracts, copy_contract_id);
            let contract_x_id = contract.xId;
            if (x_id == contract_x_id) {
                sign = true;
                break ;
            } else {
                index = index + 1;
                continue
            }
        };
        assert!(sign, NOT_EXSIT_CONTRACT);
        return table::borrow_mut(&mut contracts.contracts, *contract_id)
    }

    // -----------------------------------------AdoptContracts-----------------------------------------
    // -----------------------------------------Record-----------------------------------------

    /// 获取回访记录的备注
    public
    (package) fun
    getRecordAuditRemark(record: & Record):
    String {
        record.auditRemark
    }

    /// 设置回访记录的备注
    public
    (package) fun
    setRecordAuditRemark(record: &mut
    Record,
                         remark:
                         String)
    {
        record.auditRemark = remark
    }

    /// 获取回访记录的审核结果
    public
    (package) fun
    get_record_audit_result(record: & Record):
    Option<bool> {
        record.auditResult
    }

    /// 设置回访记录的审核结果
    public(package) fun set_record_audit_result(record: &mut Record, result: Option<bool>) {
        record.auditResult = result
    }

    /// 获取回访记录的年月记录上传图片的日期
    public(package) fun get_record_year_month(record: & Record): u64 {
        record.yearMonth
    }
    // -----------------------------------------Record-----------------------------------------


    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}
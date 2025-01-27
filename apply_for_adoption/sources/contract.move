/// Module: apply_for_adoption
module apply_for_adoption::contract {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self, ID};
    use std::string::String;
    use std::vector;
    use sui::event;
    use sui::table::{Self, Table, new};
    use sui::transfer;
    use std::option::{Option, Self, some, none, is_some, extract, borrow};
    use apply_for_adoption::lock_stake::{Self, LockedStake};

    //==============================================================================================
    // Error codes
    //==============================================================================================
    /// 缺少质押合同
    const LackLockStakeException: u64 = 108;

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
        locked_stake: Option<LockedStake>,
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
            animal_contracts: table::new<String, vector<ID>>(ctx);,
            user_contracts: table::new<String, vector<ID>>(ctx);,
            contracts: table::new<ID, AdoptContract>(ctx),
        });
        // todo 添加平台地址，避免其他人生成合同
    }

    //==============================================================================================
    // Functions
    //==============================================================================================
    /// 创建新的记录
    public(package) fun create_new_record(pic: String): Record {
        Record {
            pic,
            date: clock::timestamp_ms(ctx),
            yearMonth,
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
            locked_stake: none(),
            // 审核通过次数
            auditPassTimes: 0,
            // 捐赠给平台的币
            donateAmount,
        }
    }

    //==============================================================================================
    // Getter/Setter Functions
    //==============================================================================================

    // -----------------------------------------AdoptContract-----------------------------------------
    /// 获取合约中的
    public(package) fun get_lock_stake(contract: &mut AdoptContract): &mut LockedStake {
        assert!(is_some(&contract.locked_stake), LackLockStakeException);
        option::borrow_mut(&mut contract.locked_stake)
    }

    /// 获取合约的动物id
    public fun get_contrac_animal_id(contract: &AdoptContract): String {
        contract.animalId
    }

    /// 获取合约的状态
    public fun get_contract_status(contract: &AdoptContract): u8 {
        contract.status
    }

    /// 设置合约的状态
    public fun set_contract_status(contract: &AdoptContract, status: u8) {
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

    /// 获取合约的质押合同
    public(package) fun get_contrac_locked_stake(contract: &AdoptContract): & Option<LockedStake> {
        &contract.locked_stake
    }

    /// 设置合约的质押合同
    // public(package) fun setContracLockedStake(contract: &mut AdoptContract, new_ls: LockedStake) {
    //     option::fill(&mut contract.ls, new_ls);
    // }
    public(package) fun set_contrac_locked_stake(contract: &mut AdoptContract,
                                                 new_ls: LockedStake,
                                                 ctx: &mut TxContext) {
        // 获取合约的质押合同
        // let old_ls_option = contract::getContracLockedStake(contract);
        // let old_ls = option::extract(&mut old_ls_option);
        // 销毁旧的质押合同
        // let _ = lock_stake::destroy(old_ls,ctx);
        // 再赋值新的
        option::fill(&mut contract.locked_stake, new_ls);
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
    public(package) fun get_contract_records(contract: &AdoptContract): &mut vector<Record> {
        &mut contract.records
    }

    /// 获取合约的用户id
    public(package) fun getContractXId(contract: &AdoptContract): String {
        contract.xId
    }

    /// 获取合约ID
    public(package) fun getContractID(contract: &AdoptContract): ID {
        contract.id
    }

    // ----------------------------------------AdoptContract-----------------------------------------
    // -----------------------------------------AdoptContracts-----------------------------------------
    /// 获取合约集合
    public(package) fun get_adopt_contracts(adopt_contracts: &AdoptContracts): &mut Table<ID, AdoptContract> {
        &mut adopt_contracts.contracts
    }

    /// 获取合约集的动物合约
    public(package) fun get_animal_contract_table(adopt_contracts: &AdoptContracts): &mut Table<String, vector<ID>> {
        &mut adopt_contracts.animal_contracts
    }

    /// 获取合约集的用户合约
    public(package) fun get_user_contract_table(adoptContracts: &AdoptContracts): &mut  Table<String, vector<ID>> {
        &mut adoptContracts.user_contracts
    }

    // -----------------------------------------AdoptContracts-----------------------------------------
    // -----------------------------------------Record-----------------------------------------

    /// 获取回访记录的备注
    public(package) fun getRecordAuditRemark(record: &Record): String {
        record.auditRemark
    }

    /// 设置回访记录的备注
    public(package) fun setRecordAuditRemark(record: &mut Record, remark: String) {
        record.auditRemark = remark
    }

    /// 获取回访记录的审核结果
    public(package) fun get_record_audit_result(record: &Record): Option<bool> {
        record.auditResult
    }

    /// 设置回访记录的审核结果
    public(package) fun set_record_audit_result(record: &mut Record, result: Option<bool>) {
        record.auditResult = result
    }

    /// 获取回访记录的年月记录上传图片的日期
    public(package) fun get_record_year_month(record: &Record): u64 {
        record.yearMonth
    }
    // -----------------------------------------Record-----------------------------------------


    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}
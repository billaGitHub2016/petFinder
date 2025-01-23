/// Module: apply_for_adoption
module apply_for_adoption::apply_for_adoption {
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
    use sui_system::sui_system::{Self, SuiSystemState};
    use apply_for_adoption::lock_stake::{Self, LockedStake, stake, unstake};
    use sui::clock::{Clock, Self};

    //==============================================================================================
    // Constants
    //==============================================================================================
    /// 0-未生效
    const NotYetInForce: u8 = 0;
    /// 1-生效
    const InForce: u8 = 1;
    /// 2-完成（完成回访）
    const Finish: u8 = 2;
    /// 3-放弃
    const GiveUp: u8 = 3;
    /// 4-异常
    const Unusual: u8 = 4;

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
    const NotExsitContract: u64 = 103;
    /// 重复上传
    const RepeatUploadException: u64 = 104;
    /// 审核异常
    const AuditException: u64 = 105;
    /// 押金异常
    const ContractAmountException: u64 = 106;
    /// 回访次数异常
    const ContractRecordTimesException: u64 = 107;
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
        records: vector<Recort>,
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
        ls: Option<LockedStake>,
        // 审核通过次数
        auditPassTimes: u64,
    }

    // 回访记录
    public struct Recort has store, drop { // TODO 拼写错误
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
        animalContracts: Table<String, vector<ID>>,
        // key:xId value:vector<ID> x用户id，合约
        userContracts: Table<String, vector<ID>>,
        contracts: Table<ID, AdoptContract>,
    }

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
    // Init
    //==============================================================================================
    fun init(ctx: &mut TxContext) {
        // 公共浏览所有的合约
        transfer::share_object(AdoptContracts {
            id: object::new(ctx),
            animalContracts: table::new<String, vector<ID>>(ctx),
            userContracts: table::new<String, vector<ID>>(ctx),
            contracts: table::new<ID, AdoptContract>(ctx),
        });
    }

    //==============================================================================================
    // Entry Functions
    //==============================================================================================
    // 创建合约
    public entry fun create_adopt_contract( // TODO 看看要不要加权限校验，只有平台的钱包地址能创建合同，下面的改合同状态，销毁合同等操作同理
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
        // 获取 transcation 需要的信息
        ctx: &mut TxContext,
    ) {
        // todo 怎么确认当前创建合约的人是平台不是其他人
        // 平台
        let owner = sui::tx_context::sender(ctx);
        // 查询动物是否有被领养
        let animalContains = table::contains(&adoptContracts.animalContracts, animalId);
        // 校验合约押金应该>0
        assert!(amount > 0, ContractAmountException);
        // 校验回访次数应该 >0
        assert!(recordTimes > 0, ContractRecordTimesException);
        if (animalContains) {
            // 注意：不存在会报错
            let contractIds = table::borrow_mut(&mut adoptContracts.animalContracts, animalId);
            let contractLenght = vector::length(contractIds);
            let mut index = 0;
            while (contractLenght > index) {
                let contractId = vector::borrow(contractIds, index);
                // 解引用
                let copyContractId = *contractId;
                let contract =
                    table::borrow(&adoptContracts.contracts, copyContractId);
                // 校验动物不存在生效或完成的合同
                assert!(contract.status != InForce || contract.status != Finish, AdoptedException);
                index = index + 1;
            };
        };
        let userContains = table::contains(&adoptContracts.userContracts, animalId);
        if (userContains) {
            // 查询该用户是否有异常领养记录
            let contractIds = table::borrow(&adoptContracts.userContracts, xId);
            let contractlength = vector::length(contractIds);
            let mut index = 0;
            while (contractlength < index) {
                let contractId = vector::borrow(contractIds, index);
                // 解引用
                let copyContractId = *contractId;
                let contract = table::borrow(&adoptContracts.contracts, copyContractId);
                index = index + 1;
                // 校验动物不存在生效或完成的合同
                assert!(contract.status != Unusual, UnsusalException);
            };
        };
        // 创建新的合同
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        // 空回访记录
        let records = vector::empty<Recort>();
        // 合约状态：未生效
        let status = NotYetInForce;
        let remark = b"".to_string();
        // 创建一个新的领养合约
        let new_contract = AdoptContract {
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
            ls: none(),
            // 审核通过次数
            auditPassTimes: 0,
        };
        // 放到合约记录中
        if (animalContains) {
            // 存在则直接添加
            let animalContracts = table::borrow_mut(&mut adoptContracts.animalContracts, animalId);
            // todo 验证是否添加上去了
            vector::push_back(animalContracts, id);
        };
        if (userContains) {
            // 存在则直接添加
            let userContains = table::borrow_mut(&mut adoptContracts.userContracts, xId);
            // todo 验证是否添加上去了
            vector::push_back(userContains, id);
        };
        // 合同信息加入到合同列表中
        table::add(&mut adoptContracts.contracts, id, new_contract);
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

    /// 平台-销毁未生效合约，非未生效合约会报错并中止
    public entry fun destory_adopt_contact(
        animalId: String,
        xId: String,
        adoptContains: &mut AdoptContracts,
        ctx: &mut TxContext,
    ) {
        // 从合约中找到对应的合约,并移除
        // 从动物合约list 中移除该用户的合约
        if (table::contains(&mut adoptContains.userContracts, xId)) {
            let userContracts = table::borrow_mut(&mut adoptContains.userContracts, xId);
            // 找到对应的合同
            let (contractOption, index) = getAdoptContract(userContracts, &mut adoptContains.contracts, animalId);
            // 校验合同一定存在
            assert!(is_some(&contractOption), NotExsitContract);
            // 获取 option 内部值
            let contract = option::destroy_some(contractOption);
            let owner = sui::tx_context::sender(ctx);
            // 校验是否是创建者创建
            assert!(contract.platFormAddress == owner, ErrorAddress);
            // 移除合约
            let removeContractId = vector::swap_remove(userContracts, index);
            //  删除合约
            let _ = table::remove(&mut adoptContains.contracts, removeContractId);
        };
        // 从用户合约list 中移除该动物的合约
        if (table::contains(&adoptContains.animalContracts, animalId)) {
            let adoptContracts = table::borrow_mut(&mut adoptContains.animalContracts, animalId);
            // 找到对应的用户
            let mut index = 0;
            let mut contractslength = vector::length(adoptContracts);

            while (contractslength > index) {
                let contractId = vector::borrow(adoptContracts, index);
                let conpyContractId = *contractId;
                let contract = table::borrow(&adoptContains.contracts, conpyContractId);
                if (contract.xId == xId) {
                    // 移除合约
                    let _ = vector::swap_remove(adoptContracts, index);
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
        let contract = updateAdoptContractStatus(animalId, xId, adoptContains, remark, GiveUp, ctx);
        let adoptContractID = contract.id;
        let adoptContract = table::borrow_mut(&mut adoptContains.contracts, adoptContractID);
        /// 退养后押金处理
        /// 用户退养后，平台可解锁质押合同，按比例退还押金与利息
        /// 退还比例：（质押期间的利息+本金）/ （合约需要记录的次数+1）* 审核通过次数
        let lock_stake = getLockStake(adoptContract);
        let _ = lock_stake::unstake(lock_stake, sui_system, adoptContract, false, ctx);
    }

    /// 平台-更新合约状态：异常，并添加备注
    /// 用户长时间不上传，平台可设置为异常状态
    public entry fun unusual_adopt_contract(
        animalId: String,
        xId: String,
        adoptContains: &mut AdoptContracts,
        remark: String,
        sui_system: &mut SuiSystemState,
        ctx: &mut TxContext,
    ) {
        let contract = updateAdoptContractStatus(animalId, xId, adoptContains, remark, Unusual, ctx);
        /// 异常状态押金处理：全数退还给平台
        let lock_stake = getLockStake(&mut contract);
        let _ = lock_stake::unstake(lock_stake, sui_system, &mut contract, false, ctx, );
    }

    /// 用户-签署合同并缴纳押金
    public fun sign_adopt_contract(adoptContractID: ID, adoptContains: &mut AdoptContracts
                                   , sui_system: &mut SuiSystemState, ctx: &mut TxContext) {
        // 校验合同是否存在
        let adoptContract = table::borrow_mut(&mut adoptContains.contracts, adoptContractID);
        assert!(adoptContract.status == NotYetInForce, NotExsitContract);
        // 校验合同是否是该用户可以签署的
        assert!(adoptContract.adopterAddress == sui::tx_context::sender(ctx), ErrorAddress);
        // 校验用户是否已经签署过该合同
        assert!(adoptContract.status != InForce, AdoptedException);
        // 创建质押合同
        let ls = lock_stake::new_locked_stake(ctx);
        // 质押
        lock_stake::stake(ls, sui_system, adoptContract.platFormAddress, ctx, adoptContract);
        // 更新合同状态
        adoptContract.status = InForce;
        // todo 通知前端
    }

    /// 用户-上传回访记录
    public fun upload_record(
        ctx: &mut TxContext,
        adoptContractID: ID,
        adoptContains: &mut AdoptContracts,
        pic: String
    ) {
        // 校验合同是否存在
        let adoptContract = table::borrow_mut(&mut adoptContains.contracts, adoptContractID);
        assert!(adoptContract.status == InForce, NotExsitContract);
        // 校验合同是否是该用户可以签署的
        assert!(adoptContract.adopterAddress == sui::tx_context::sender(ctx), ErrorAddress);
        // 校验合同是否已经完成回访
        assert!(adoptContract.status != Finish, AdoptedException);
        // todo 检查能否获取当前年月
        let yearMonth = clock::timestamp_ms(clock) / 1000 / 60 / 60 / 24 / 30;
        // 获取最后一次上传记录
        let len = vector::length(&adoptContract.records);
        let lastRecord = vector::borrow(&adoptContract.records, len - 1);
        // 校验最后一次记录平台需要审核，最后一次记录没有审核，无法上传新的记录
        assert!(lastRecord.auditResult != none(), AuditException);
        // 获取最后一次上传记录的年月
        let lastYearMonth = lastRecord.yearMonth;
        // 获取最后一次上传记录审批结果
        let lastAuditResult = lastRecord.auditResult;
        if (lastAuditResult != none() && extract(&mut lastAuditResult)) {
            // 校验是否有重复上传
            assert!(yearMonth != lastYearMonth, RepeatUploadException);
        };
        let record = Recort {
            pic,
            date: clock::timestamp_ms(ctx),
            yearMonth,
            auditResult: none(),
            auditRemark: b"".to_string(),
        };
        // 上传回访记录
        vector::push_back(&mut adoptContract.records, record);
        // todo 通知前端有用户上传回访记录
    }

    // todo 平台-审核上传的回访记录
    public fun audit_record(ctx: &mut TxContext, adoptContractID: ID, adoptContains: &mut AdoptContracts, // TODO ctx: &mut TxContext这个参数要放在最后，否则无法调用这个方法
                            // 审核结果：true-通过；false-不通过
                            auditResult: bool,
                            // 审核备注
                            auditRemark: String) {
        // 校验合同是否存在
        let adoptContract = table::borrow_mut(&mut adoptContains.contracts, adoptContractID);
        assert!(adoptContract.status == InForce, NotExsitContract);
        // 校验当前用户是否是平台
        assert!(adoptContract.platFormAddress == sui::tx_context::sender(ctx), ErrorAddress);
        // 审核通过增加审核通过次数
        if (auditResult) {
            adoptContract.auditPassTimes = adoptContract.auditPassTimes + 1;
        };
        // 获取最后一次上传记录
        let len = vector::length(&adoptContract.records);
        let lastRecord = vector::borrow_mut(&mut adoptContract.records, len - 1);
        // 更新回访记录备注
        lastRecord.auditRemark = auditRemark;
        // 更新审核结果
        lastRecord.auditResult = Some(auditResult);
        // 校验合同审核通过次数是否等于需要记录次数
        if (adoptContract.auditPassTimes == adoptContract.recordTimes) {
            // 更新合同状态
            adoptContract.status = Finish;
            let lock_stake = getLockStake(adoptContract);
            // 退还押金与利息
            let _ = lock_stake::unstake(lock_stake, sui_system, adoptContract, true, ctx);
        };
        // todo 通知用户审核结果
    }

    //==============================================================================================
    // Getter Functions
    //==============================================================================================
    /// 在用户领养的合约种根据动物id找到对应的合同
    fun getAdoptContract(
        contractIds: &mut vector<ID>,
        contracts: &mut Table<ID, AdoptContract>,
        animalId: String
    ): (Option<AdoptContract>, u64) {
        let mut index = 0;
        let contractslength = vector::length(contractIds);
        while (contractslength > index) {
            let contractId = vector::borrow_mut(contractIds, index);
            let copyContractId = *contractId;
            let contract = table::remove(contracts, copyContractId);
            if (contract.animalId == animalId) {
                return (some((contract)), index)
            } else {
                index = index + 1;
                continue
            }
        };
        return (option::none(), index)
    }

    /// 获取异常状态值
    public fun getUnusualStatus(): u8 {
        Unusual
    }

    /// 获取缺失质押合同异常状态
    public fun getLackLockStakeExceptionStatus(): u64 {
        LackLockStakeException
    }

    /// 获取合约中的
    public(package) fun getLockStake(contract: &mut AdoptContract): &mut LockedStake {
        let lock_stake = contract.ls;
        assert!(is_some(&lock_stake), LackLockStakeException);
        option::borrow_mut(&mut lock_stake)
    }

    /// 获取合约的状态
    public fun getContractStatus(contract: &AdoptContract): u8 {
        contract.status
    }

    /// 获取合约的押金数量
    public(package) fun getContractAmount(contract: &AdoptContract): u64 {
        contract.amount
    }

    /// 获取合约的押金数量
    public(package) fun getContractRecordTimes(contract: &AdoptContract): u64 {
        contract.recordTimes
    }

    /// 获取合约的押金数量
    public(package) fun getContracLockedStake(contract: &AdoptContract): Option<LockedStake> {
        contract.ls
    }

    /// 获取合约的领养用户地址
    public(package) fun getContracAdopterAddress(contract: &AdoptContract): address {
        contract.adopterAddress
    }

    /// 获取合约的平台地址
    public(package) fun getContracPlatFormAddress(contract: &AdoptContract): address {
        contract.platFormAddress
    }

    /// 获取合约的审核通过次数
    public(package) fun getContracAuditPassTimes(contract: &AdoptContract): u64 {
        contract.auditPassTimes
    }

    //==============================================================================================
    // setter Functions
    //==============================================================================================

    /// 设置合约的质押合同
    public(package) fun setContracLockedStake(contract: &mut AdoptContract, ls: LockedStake) {
        contract.ls = Option::some(ls);
    }

    //==============================================================================================
    // Update Functions
    //==============================================================================================
    fun updateAdoptContractStatus(
        animalId: String,
        xId: String,
        adoptContains: &mut AdoptContracts,
        remark: String,
        status: u8,
        ctx: &mut TxContext,
    ): AdoptContract {
        assert!(!table::contains(&mut adoptContains.userContracts, xId));
        let userContracts = table::borrow_mut(&mut adoptContains.userContracts, xId);
        // 找到对应的合同
        let (contractOption, _) = getAdoptContract(userContracts, &mut adoptContains.contracts, animalId);
        // 校验合同一定存在
        assert!(is_some(&contractOption), NotExsitContract);
        // 获取 option 内部值
        let adoptContract = option::destroy_some<(AdoptContract)>(contractOption);
        let owner = sui::tx_context::sender(ctx);
        // 校验是否是创建者创建
        assert!(adoptContract.platFormAddress == owner, ErrorAddress);
        // 更新状态
        adoptContract.status = status;
        adoptContract.remark = remark;
        // todo 通知前端
        adoptContract
    }
    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



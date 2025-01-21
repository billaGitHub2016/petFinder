/// Module: apply_for_adoption
module apply_for_adoption::apply_for_adoption {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use std::string;
    use sui::object::{UID, Self, ID};
    use std::string::String;
    use std::vector;
    use sui::balance::{Balance, Self};
    use sui::event;
    use sui::table::{Self, Table, new};
    use sui::clock::Clock;
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui_system::staking_pool::StakedSui;
    use sui_system::sui_system::{Self, SuiSystemState};
    // use sui::balance::{Self, Balance};
    use std::option::{Option, Self, some, none, is_some, extract};


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

    const EInsufficientBalance: u64 = 0;

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
    }

    // 回访记录
    public struct Recort has store, drop {
        // 宠物图片
        pic: String,
        // 记录日期
        // date: Clock,
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
        // 获取 transcation 需要的信息
        ctx: &mut TxContext,
    ) {
        // 平台
        let owner = sui::tx_context::sender(ctx);
        // 查询动物是否有被领养
        let animalContains = table::contains(&adoptContracts.animalContracts, animalId);
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
            id: id,
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
            remark
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

    /// 平台-销毁未生效合约，非非未生效合约会报错并中止
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
        updateAdoptContractStatus(animalId, xId, adoptContains, remark, GiveUp, ctx)
    }

    // 更新合约状态：异常，并添加备注
    public entry fun unusual_adopt_contract(
        animalId: String,
        xId: String,
        adoptContains: &mut AdoptContracts,
        remark: String,
        ctx: &mut TxContext,
    ) {
        updateAdoptContractStatus(animalId, xId, adoptContains, remark, Unusual, ctx)
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
            }else {
                index = index + 1;
                continue
            }
        };
        return (option::none(), index)
    }

    // todo 所有人均可获取当前的所有合约
    public fun get_all_adopt_contract() {}

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
    ) {
        if (table::contains(&mut adoptContains.userContracts, xId)) {
            let userContracts = table::borrow_mut(&mut adoptContains.userContracts, xId);
            // 找到对应的合同
            let (contractOption, _) = getAdoptContract(userContracts, &mut adoptContains.contracts, animalId);
            // 校验合同一定存在
            assert!(is_some(&contractOption), NotExsitContract);
            // 获取 option 内部值
            let mut adoptContract = option::destroy_some<(AdoptContract)>(contractOption);
            let owner = sui::tx_context::sender(ctx);
            // 校验是否是创建者创建
            assert!(adoptContract.platFormAddress == owner, ErrorAddress);
            // 更新状态
            adoptContract.status = status;
            adoptContract.remark = remark;
            // 将修改后的合约放回Table
            table::add(&mut adoptContains.contracts, adoptContract.id, adoptContract);
            // todo 通知前端
        }
    }


    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



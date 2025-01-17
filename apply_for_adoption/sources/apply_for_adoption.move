/// Module: apply_for_adoption
module apply_for_adoption::apply_for_adoption {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use std::string;
    use sui::object::{UID, Self};
    use std::string::String;
    use std::vector;
    use sui::clock;
    use sui::kiosk::Listing;
    use sui::table::{Self, Table, new};
    use sui::clock::Clock;
    use sui::transfer;

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
    const AdoptedException: u16 = 1;
    /// 领养异常
    const UnsusalException: u16 = 2;

    //==============================================================================================
    // Structs
    //==============================================================================================

    /// 领养合约 平台生成，owner 是平台
    public struct AdoptContract has key, drop {
        id: UID,
        // 领养用户xid
        xId: String,
        // 领养动物id
        animalId: String,
        // 领养花费币 <T>
        amount: u64,  // TODO 不能用u64类型，要质押币，要用Coin<SUI>或者Balance<SUI>
        // 回访记录
        records: vector<Recort>,
        // 领养人链上地址（用于交退押金）,指定领养人，避免被其他人领养
        adopterAddress: address,
        // 合约状态：0-未生效；1-生效；2-完成（完成回访）；3-放弃；4-异常
        status: u8,
        // 备注
        remark: String,
    }

    // 回访记录
    public struct Recort has key, drop {
        id: UID,
        // 宠物图片
        pic: String,
        // 记录日期
        date: Clock, // TODO 要用u64，保存时间戳即可
    }

    // 动物信息
    public struct Animal has key, drop {
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
    public struct AdoptContracts has key, drop {
        id: UID,
        // key:animalId value:vector<AdoptContract> 动物id，合约
        adoptContracts: Table<String, vector<AdoptContract>>,
        // key:xId value:vector<AdoptContract> x用户id，合约
        userContracts: Table<String, vector<AdoptContract>>,
    }

    // 创建领养合约 （平台）
    public struct AdoptContractCreate has copy, drop {
        id: UID,
        // 领养人的x账号
        xId: String,
        // 领养动物id
        animalId: UID,
        // 领养合约金额
        amount: u64,
        // 领养人链上地址（用于交退押金）
        adopterAddress: address,
    }

    //==============================================================================================
    // Event Structs
    //==============================================================================================


    //==============================================================================================
    // Init
    //==============================================================================================
    fun init(ctx: &mut TxContext) {
        // 公共浏览所有的合约
        transfer::share_ooject(AdoptContracts { // TODO 拼写错误
            id: object::new(ctx),
            adoptContracts: table::new(ctx),
            userContracts: table::new(ctx),
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
        // 获取 transcation 需要的信息
        ctx: &mut TxContext,
        // 合约记录
        adoptContracts: &mut AdoptContracts,
    ) {
        // 平台
        let owner = tx_context::sender(ctx);
        // todo 校验
        // 查询动物是否有被领养
        let animalContains = table::contains(&adoptContracts.adoptContracts, animalId);
        if (animalContains) {
            // 注意：不存在会报错
            let animalContracts = table::borrow(&adoptContracts.adoptContracts, animalId);
            let animalContractslength = vector::length(animalContracts);
            let animalIndex = 0;
            while (animalContractslength < animalIndex) {
                let animalContract = vector::borrow(animalContracts, index);
                animalIndex = animalIndex + 1;
                // 校验动物不存在生效或完成的合同
                assert!(animalContract.status == InForce || animalContract.status == Finish, AdoptedException);
            };
        };
        let userContains = table::contains(&adoptContracts.userContracts, animalId);
        if (userContains) {
            // 查询该用户是否有异常领养记录
            let userContracts = table::borrow(&adoptContracts.userContracts, xId);
            let userContractslength = vector::length(userContracts);
            let userIndex = 0;
            while (userContractslength < userIndex) {
                let userContract = vector::borrow(userContracts, index);
                userIndex = userIndex + 1;
                // 校验动物不存在生效或完成的合同
                assert!(userContract.status == Unusual, UnsusalException);
            };
        };
        // 创建新的合同
        let uid = object::new(ctx);
        // 将UID引用转换为ID
        let id = object::uid_to_inner(&uid);
        // 空回访记录
        let records = vector::empty<Recort>();
        // 合约状态：未生效
        let status = NotYetInForce;
        let remark = String::new();
        // 创建一个新的领养合约
        let new_contract = AdoptContract {
            id: uid,
            // 领养用户xid
            xId,
            // 领养动物id
            animalId,
            // 领养花费币 <T>
            amount,
            // 回访记录
            records,
            // 领养人链上地址（用于交退押金）,指定领养人，避免被其他人领养
            adopterAddress,
            // 合约状态：0-未生效；1-生效；2-完成（完成回访）；3-放弃；4-异常
            status,
            // 备注
            remark
        };
        // 平台拥有合约
        transfer::transfer(new_contract, owner); // TODO 比较大的问题，这个合约应该要是share object，否则用户不能使用这个合约对象，也就不能做签约等操作
        // 放到合约记录中
        if (animalContains) {
            // 存在则直接添加
            let animalContracts = table::borrow_mut(&mut adoptContracts.adoptContracts, animalId);
            // todo 验证是否添加上去了
            vector::push_back(animalContracts, new_contract);
        };
        if (userContains) {
            // 存在则直接添加
            let userContains = table::borrow_mut(&mut adoptContracts.userContracts, xId);
            // todo 验证是否添加上去了
            vector::push_back(userContains, new_contract);
        };
    }
    // 销毁合同，领养人在签署领养前销毁
    // 过时没有签约的也需要销毁
    // 放弃领养，领养人领养不合适时后，退养。更新合同状态为放弃
    // 签署合同
    //==============================================================================================
    // Getter Functions
    //==============================================================================================

    // 所有人均可获取当前的所有合约
    public fun get_all_adopt_contract() {}

    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



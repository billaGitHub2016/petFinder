/// Module: apply_for_adoption
module apply_for_adoption::apply_for_adoption {
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::object::{UID, Self};
    use std::string::String;
    use sui::kiosk::Listing;
    use sui::table::{Self, Table};

    //==============================================================================================
    // Constants
    //==============================================================================================

    //==============================================================================================
    // Error codes
    //==============================================================================================

    //==============================================================================================
    // Structs
    //==============================================================================================


    //==============================================================================================
    // Event Structs
    //==============================================================================================

    /// 领养合约 平台生成，owner 是平台
    // 交易是两个人的，怎么体现
    public struct AdoptContract has key, drop {
        id: UID,
        // 领养用户xid
        xId: String,
        // 领养动物id
        animalId: String,
        // 领养花费币 <T>
        amount: u64,
        // 回访记录 可变
        records: vector<Recort>,
        // 领养人链上地址（用于交退押金）
        adopterAddress: address

    }

    // 回访记录
    public struct Recort has key, drop {
        // 宠物图片
        // 记录日期
    }

    // 所有的领养合约
    public struct AdoptContractList has key, drop {
        id: UID,
        // key:owner address, value:AdoptContract
        adoptContracts: Table<address, AdoptContract>
    }

    // 领养失败队列
    // 领养成功队列
    // 创建领养合约 （平台）
    public struct AdoptContractCreate has copy, drop {
        id: UID,
        // 领养人的x账号
        xId: String,
        // 领养动物id
        animalId: String,
        // 领养合约金额
        amount: u64,
        // 领养人链上地址（用于交退押金）
        adopterAddress: address
    }
    // 把合同存放到待领养队列

    //==============================================================================================
    // Init
    //==============================================================================================
    fun init(ctx: &mut TxContext) {
        // 公共浏览所有的合约
        transfer::share_ooject(AdoptContractList {
            id: object::new(ctx),
            adoptContracts: table::new(ctx),
        });
    }

    //==============================================================================================
    // Entry Functions
    //==============================================================================================
    // 创建合约
    public entry fun create_adopt_contract(
        id: UID,
        // 领养人的x账号
        xId: String,
        // 领养动物id
        animalId: String,
        // 领养合约金额
        amount: u64,
        // 领养人链上地址（用于交退押金）
        adopterAddress: address,
        // 增加记录
        adoptContractList: &mut AdoptContractList,
        ctx: &mut TxContext
    ){
        // 平台
        let owner = tx_context::sender(ctx);
        // todo 校验

        //
        let uid = object::new(ctx);
        // 将UID引用转换为ID
        let id = object::uid_to_inner(&uid);
        // 创建一个新的领养合约
        let new_profile = AdoptContract {
            id: uid,

        };
    }
    //==============================================================================================
    // Getter Functions
    //==============================================================================================

    // 所有人均可获取当前的所有合约
    public fun get_all_adopt_contract() {

    }

    //==============================================================================================
    // Helper Functions
    //==============================================================================================
}



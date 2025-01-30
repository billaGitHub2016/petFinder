#[test_only]
module apply_for_adoption::apply_for_adoption_tests {

    const ENotImplemented: u64 = 0;
    //==============================================================================================
    // Dependencies
    //==============================================================================================
    use sui::test_scenario::{Self, Scenario};
    // uncomment this line to import the module
    use apply_for_adoption::apply_for_adoption::{
        Self,
        init_for_testing,
        get_contract, create_adopt_contract, sign_adopt_contract,
        get_in_force_status, get_contract_records, get_contract_status, get_x_id,
        upload_record, audit_record, AdoptContract, AdoptContracts, PublicUid, get_contrac_id
    };
    use std::string::{String, Self};
    use sui::coin::{Coin, Self};
    use sui::sui::SUI;
    use std::vector::{Self, length, empty, push_back};
    use sui_system::sui_system::{Self, SuiSystemState, request_add_stake_non_entry, request_withdraw_stake_non_entry};

    //==============================================================================================
    // Error codes
    //==============================================================================================
    #[allow(unused_const)]
    const CREATE_SIGN_ADOPT_CONTRACT_ERROR: u64 = 201;
    // test_upload_contract
    #[allow(unused_const)]
    const UPLOAD_CONTRACT_ERROR: u64 = 202;
    //==============================================================================================
    // test
    //==============================================================================================

    #[test]
    /// 平台-测试创建合约
    fun test_create_adopt_contract() {
        // 平台
        let mut platfrom_scenario = test_scenario::begin(get_platform_address());

        // 初始化平台
        init_for_testing(platfrom_scenario.ctx());
        platfrom_scenario.next_tx(get_platform_address());
        // 合同集合
        let mut contracts = platfrom_scenario.take_shared<AdoptContracts>();
        // 创建合同
        create_adopt_contract_fun(get_test_x_id(), get_test_animal_id(), &mut contracts, platfrom_scenario.ctx());
        // 从平台校验是否能获取到新增的合同
        let contract = get_contract(&mut contracts, get_test_animal_id(), get_test_x_id());
        assert!(get_x_id(contract) == get_test_x_id(), 100);
        test_scenario::return_shared(contracts);
        // 结束平台测试
        test_scenario::end(platfrom_scenario);
    }

    // todo 测试被领养了的动物不能生成领养合同
    // todo 测试有异常状态合同用户的不能生成
    //
    #[test]
    /// 用户-测试签署合约
    fun test_sign_adopt_contract() {
        /// 平台-创建合同
        // 平台
        let mut platfrom_scenario = test_scenario::begin(get_platform_address());
        // 初始化平台
        init_for_testing(test_scenario::ctx(&mut platfrom_scenario));
        // 合同集合
        let mut contracts = platfrom_scenario.take_shared<AdoptContracts>();
        // 创建合同
        create_adopt_contract_fun(get_test_x_id(), get_test_animal_id(), &mut contracts, test_scenario::ctx(&mut platfrom_scenario));
        /// 用户-签署测试合同
        // 用户
        let mut user_scenario = test_scenario::begin(get_user_address());
        // 合同集合
        let contracts = test_scenario::take_shared<AdoptContracts>(&mut platfrom_scenario);
        let public_uid = test_scenario::take_shared<PublicUid>(&mut platfrom_scenario);
        // 获取刚创建的合同
        let contract = sign_contract(&mut contracts, &mut public_uid, &user_scenario, user_scenario.ctx());
        // 校验合同状态为已生效
        assert!(get_contract_status(contract) == get_in_force_status(), CREATE_SIGN_ADOPT_CONTRACT_ERROR);
        // share_object 还回去
        test_scenario::return_shared(contracts);
        test_scenario::return_shared(public_uid);
        // 结束测试
        test_scenario::end(platfrom_scenario);
        // 结束用户
        test_scenario::end(user_scenario);
    }
    //
    // // todo 测试非用户签约
    //
    // #[test]
    // /// 用户-上传记录
    // fun test_upload_contract() {
    //     /// 平台-创建合同
    //     // 平台
    //     let mut platfrom_scenario = test_scenario::begin(get_platform_address());
    //     // 初始化平台
    //     init_for_testing(test_scenario::ctx(&mut platfrom_scenario));
    //     let plat_form_ctx = test_scenario::ctx(&mut platfrom_scenario);
    //     // 创建合同
    //     create_adopt_contract(plat_form_ctx, get_animal_id(), get_x_id());
    //     /// 用户-签署测试合同
    //     // 用户
    //     let user_scenario = test_scenario::begin(get_user_address());
    //     let mut user_ctx = test_scenario::ctx(&mut user_scenario);
    //     // 合同集合
    //     let contracts = test_scenario::take_shared<AdoptContracts>(&mut platform_scenario);
    //     let public_uid = test_scenario::take_shared<PublicUid>(&mut platfrom_scenario);
    //     // 获取刚创建的合同`
    //     let contract = sign_contract(&mut contracts, &mut public_uid, user_ctx);
    //     let records = get_contract_records(contract);
    //     /// 用户-上传记录
    //     let contract_id = get_contrac_id(contract);
    //     upload_record(contract_id, &mut contracts, get_pic(), clock::creat(user_ctx), user_ctx);
    //     // 校验是否存在记录
    //     assert!(!vector::is_empty(&records), UPLOAD_CONTRACT_ERROR);
    //     // share_object 还回去
    //     test_scenario::return_to_sender(plaf_form_scenario, adopt_contracts);
    //     // 结束测试
    //     test_scenario::end(plat_form_scenario);
    //     // 结束用户
    //     test_scenario::end(user_scenario);
    // }
    //
    // // todo 测试非用户上传记录
    //
    // #[test]
    // /// 平台-审核通过上传记录
    // fun test_audit_record() {
    //     ///  平台-创建合同
    //     // 平台
    //     let platfrom_scenario = test_scenario::begin(get_platform_address());
    //     // 初始化平台
    //     init_for_testing(test_scenario::ctx(&mut platfrom_scenario));
    //     let plat_form_ctx = test_scenario::ctx(&mut platfrom_scenario);
    //     // 创建合同
    //     create_adopt_contract(plat_form_ctx, get_animal_id(), get_x_id());
    //     /// 用户-签署测试合同
    //     // 用户
    //     let user_scenario = test_scenario::begin(get_user_address());
    //     let mut user_ctx = test_scenario::ctx(&mut user_scenario);
    //     // 合同集合
    //     let contracts = test_scenario::take_shared<AdoptContracts>(&mut platform_scenario);
    //     let public_uid = test_scenario::take_shared<PublicUid>(&mut platfrom_scenario);
    //     // 获取刚创建的合同
    //     let contract = sign_contract(&mut contracts, &mut public_uid, user_ctx);
    //     /// 用户-上传记录
    //     let contract_id = get_contrac_id(contract);
    //     upload_record(contract_id, &mut contracts, get_pic(), clock::creat(user_ctx), user_ctx);
    //     let mut system_state = test_scenario::take_shared<SuiSystemState>(&user_scenario);
    //     let public_uid = test_scenario::take_shared<PublicUid>(&mut platfrom_scenario);
    //     /// 平台-审核通过上传记录
    //     audit_record(contract_id, &mut contracts, true, string::utf8(b"well down!")
    //         , &mut system_state, &mut public_uid, user_ctx);
    //     // todo 测试有没有传上去
    //     // share_object 还回去
    //     test_scenario::return_to_sender(&platfrom_scenario, adopt_contracts);
    //     // 结束测试
    //     test_scenario::end(plat_form_scenario);
    //     // 结束用户
    //     test_scenario::end(user_scenario);
    // }

    // todo 平台审核不通过上传记录

    // todo 测试用户上传记录次数满足后平台退还
    // todo 测试平台判断用户弃养
    // todo 测试平台判断用户异常状态
    // todo 测试用户同一个月上传多次信息
    // todo 测试非平台用户创建会报错
    // todo 平台-销毁合同


    // todo 测试押金异常
    // todo 测试回访次数异常


    //==============================================================================================
    // Functions
    //==============================================================================================
    /// 创建合同
    fun create_adopt_contract_fun(x_id: string::String, animal_id: string::String, contracts: &mut AdoptContracts,
                                  plat_form_ctx: &mut TxContext) {
        // 平台-测试创建合同
        create_adopt_contract(
            x_id,
            animal_id,
            get_test_contract_amount(),
            get_platform_address(),
            contracts,
            get_record_times(),
            get_donate_amount(),
            plat_form_ctx
        );
    }

    /// 签署合同
    fun sign_contract(
        contracts: &mut AdoptContracts,
        public_uid: &mut PublicUid,
        user_scenario: &Scenario,
        user_ctx: &mut TxContext,
    ): &mut AdoptContract {
        let mut contract = get_contract(contracts, get_test_animal_id(), get_test_x_id());
        let contract_id = get_contrac_id(contract);
        // 获取测试 coin
        let all_amount = get_record_times() + get_donate_amount();
        let mut coin = coin::mint_for_testing<SUI>(all_amount, user_ctx);
        let mut system_state = test_scenario::take_shared<SuiSystemState>(user_scenario);
        // 用户-签署合约
        sign_adopt_contract(contract_id, contracts, &mut coin, &mut system_state, get_validator_address(),
            public_uid, user_ctx);
        test_scenario::return_shared(system_state);
        coin::burn_for_testing<SUI>(coin);
        contract
    }

    //==============================================================================================
    // getter
    //==============================================================================================
    #[allow(unused_function)]
    fun get_user_address(): address {
        @0xa
    }

    #[allow(unused_function)]
    fun get_platform_address(): address {
        @0xb
    }

    #[allow(unused_function)]
    fun get_test_x_id(): string::String {
        string::utf8(b"xId1")
    }

    #[allow(unused_function)]
    fun get_test_animal_id(): string::String {
        string::utf8(b"animalId1")
    }

    #[allow(unused_function)]
    /// 合约押金
    fun get_test_contract_amount(): u64 {
        10
    }

    #[allow(unused_function)]
    /// 上传次数
    fun get_record_times(): u64 {
        2
    }

    #[allow(unused_function)]
    /// 平台捐献
    fun get_donate_amount(): u64 {
        2
    }

    /// 获取正常的图片
    #[allow(unused_function)]
    fun get_pic(): string::String {
        string::utf8(b"aaa")
    }

    /// 获取异常的图片
    #[allow(unused_function)]
    fun get_unusual_pic(): string::String {
        string::utf8(b"bbb")
    }

    #[allow(unused_function)]
    fun get_validator_address(): address {
        @0x0
    }
}


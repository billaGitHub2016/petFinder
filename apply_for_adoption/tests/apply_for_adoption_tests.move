// #[test_only]
// module apply_for_adoption::apply_for_adoption_tests {
//
//     const ENotImplemented: u64 = 0;
//     //==============================================================================================
//     // Dependencies
//     //==============================================================================================
//     use sui::test_scenario::{Self};
//     // uncomment this line to import the module
//     use apply_for_adoption::apply_for_adoption::{Self, AdoptContracts};
//     use std::string;
//
//     #[test]
//     fun test_create_adopt_contract() {
//         // 用户
//         let user = @0xa;
//         let mut plat_fromscenario_val = test_scenario::begin(user);
//         let scenario = &mut plat_fromscenario_val;
//         // 平台
//         let platFormAddress = @0xb;
//         let mut plat_from_scenario_val = test_scenario::begin(platFormAddress);
//         let plafFormScenario = &mut plat_from_scenario_val;
//         // 获取初始化对象
//         test_scenario::next_tx(plafFormScenario, platFormAddress);
//         apply_for_adoption::init_for_test(test_scenario::ctx(plafFormScenario));
//         // 公共测试参数
//         let xId = string::utf8(b"xId1");
//         let animalId = string::utf8(b"animalId1");
//         let amount: u64 = 10;
//         let recordTimes = 2;
//
//         /// 平台-测试创建合同
//         test_scenario::next_tx(plafFormScenario, platFormAddress);
//         {
//             let mut adoptContracts = test_scenario::take_shared<AdoptContracts>(plafFormScenario);
//             apply_for_adoption::create_adopt_contract(
//                 xId,
//                 animalId,
//                 amount,
//                 platFormAddress,
//                 adoptContracts,
//                 recordTimes,
//                 test_scenario::ctx(plafFormScenario)
//             );
//             test_scenario::return_to_sender(plafFormScenario, adoptContracts);
//         };
//         // todo 测试押金异常
//         // todo 测试回访次数异常
//         // 测试用户签约
//         test_scenario::next_tx(plafFormScenario, platFormAddress);
//         test_scenario::next_tx(scenario, user);
//
//         {
//             let mut adoptContracts = test_scenario::take_shared<AdoptContracts>(scenario);
//             // 平台-创建合约
//             apply_for_adoption::apply_for_adoption::create_adopt_contract(
//                 xId,
//                 animalId,
//                 amount,
//                 platFormAddress,
//                 &mut adoptContracts,
//                 recordTimes,
//                 test_scenario::ctx(plafFormScenario)
//             );
//             let contract = apply_for_adoption::apply_for_adoption::get_contract(contracts, animalId, xId);
//             let contractId = apply_for_adoption::apply_for_adoption::getContracId(&contract);
//             // 用户-签署合约
//             apply_for_adoption::sign_adopt_contract(
//                 contractId,
//                 &mut apply_for_adoption::apply_for_adoption::AdoptContract,
//                 &mut SuiSystemState,
//                 ctx
//             );
//             test_scenario::return_to_sender(scenario, contract);
//         }
//         // todo 测试非用户签约
//         // todo 测试用户上传记录
//         // todo 测试非用户上传记录
//         // todo 测试用户上传记录次数满足后平台退还
//         // todo 测试平台判断用户弃养
//         // todo 测试平台判断用户异常状态
//         // todo 测试用户同一个月上传多次信息
//         // todo 测试非平台用户创建会报错
//         // todo 平台-销毁合同
//         // todo 平台审核上传记录
//     }
//

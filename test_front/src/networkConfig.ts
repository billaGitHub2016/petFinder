import {getFullnodeUrl, SuiClient} from "@mysten/sui/client";
import {SuiGraphQLClient} from "@mysten/sui/graphql";
import {createNetworkConfig} from "@mysten/dapp-kit";

const {networkConfig, useNetworkVariable, useNetworkVariables} =
    createNetworkConfig({
        // tx:3gvKVG73RyQxu7U2SsKAYghVL5BDGNv4DekrsaweyMpy
        testnet: {
            url: getFullnodeUrl("testnet"),
            packageID: "0xe60042bc175e34d871538fcbb8a7726ec4f304e626d15ef2b05e927a53e501bd",
            adoptContracts:"0x96e29471df8f26a32360e84e781bc70ace39a85f81abd630d4d5a3a65cd2051c",
            //https://testnet.suivision.xyz/validator/0x6d6e9f9d3d81562a0f9b767594286c69c21fea741b1c2303c5b7696d6c63618a
            // 随机找的一个测试网络 validator
            validator:"0x6d6e9f9d3d81562a0f9b767594286c69c21fea741b1c2303c5b7696d6c63618a"
        },
    });
const moudleName = "apply_for_adoption";

const suiClient = new SuiClient({
    url: networkConfig.testnet.url,
});

const suiGraphQLClient = new SuiGraphQLClient({
    url: `https://sui-testnet.mystenlabs.com/graphql`,
});

export {useNetworkVariable, useNetworkVariables, networkConfig, suiClient, suiGraphQLClient,moudleName};

import {getFullnodeUrl, SuiClient} from "@mysten/sui/client";
import {SuiGraphQLClient} from "@mysten/sui/graphql";
import {createNetworkConfig} from "@mysten/dapp-kit";

const {networkConfig, useNetworkVariable, useNetworkVariables} =
    createNetworkConfig({
        // tx:39dyqykCJyKZGZbmwfsMWNMybuTAtHgzLbARVAzmhS8X
        testnet: {
            url: getFullnodeUrl("testnet"),
            packageID: "0xd7887652b24afe393ecf7b42fc6345345b6031a5309dbe6345e78c027f93383f",
            // share ObjectId
            publicUid: "0xd66840501d035dc723e964be8310c4bc5098f5bc0a98fdebbcfc83a27d40b7f6",
            adoptContracts:"0xd9f27e83daa6a4f2f50915b806984c62fa01f5afefe9252d7d9d593fbe11b23b"
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

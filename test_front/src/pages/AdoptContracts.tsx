import {useCurrentAccount, useSignAndExecuteTransaction} from "@mysten/dapp-kit";
import {useEffect, useState} from "react";
import {AdoptContract, AdoptContracts} from "@/type";
import {adoptContractsQuery} from "@/lib/contracts";
import {networkConfig, suiClient} from "@/networkConfig.ts";
import { toast } from "@/components/ui/use-toast";
// import { suiClient } from "@/networkConfig";
const AdoptContracts = () => {
    const [adoptContracts, setAdoptContracts] = useState<AdoptContracts | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        const fetchContracts = async () => {
            try {
                const data = await adoptContractsQuery();// 等待 Promise 解析
                debugger
                console.log(data)
                suiClient.getObject(networkConfig.testnet.adoptContracts)
            } catch (err) {
                setError(err.message);
            } finally {
                setIsLoading(false);
            }
        };
        fetchContracts();
    }, []);

    if (isLoading) return <div>Loading...</div>;
    if (error) return <div>Error: {error}</div>;

    return (<div>done</div>);
    //     <div>
    //         <h1>Adopt Contracts</h1>
    //         <ul>
    //             {adoptContracts ?.contracts.map((contract) => ( // 使用可选链操作符处理可能的 null
    //                 <li key={contract.contractId}>
    //                     {/* 假设 contract 有 id 和 name 属性 */}
    //                     {contract.adoptContract.animalId} (ID: {contract.adoptContract.xId})
    //                 </li>
    //             ))}
    //         </ul>
    //     </div>
    // );
};

export default AdoptContracts;





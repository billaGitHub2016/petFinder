import { Button, Modal, Checkbox, message, Space } from "antd";
import type { CheckboxProps } from "antd";
import {
  forwardRef,
  Ref,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
  useContext,
} from "react";
import {
  useSignAndExecuteTransaction,
  useSuiClient,
  useCurrentAccount,
} from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { SUI_SYSTEM_STATE_OBJECT_ID } from "@mysten/sui/utils";
import type { DataType as Contract } from "./Contracts";
import { SUI_MIST, PACKAGE_ID, CONTRACTS_CONTAINER } from "@/config/constants";
import { useNetworkVariable } from "@/config";
import { useParams } from "next/navigation";
import { getDictionary } from "@/lib/i18n";

const SignContractModal = (
  {
    contract,
    onSuccess,
  }: {
    contract?: Contract | null;
    onSuccess?: () => void;
  },
  ref: Ref<{
    setOpen: Function;
  }>
) => {
  const [messageApi, contextHolder] = message.useMessage();
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [isAgree, setIsAgree] = useState(false);
  const account = useCurrentAccount();
  const validator = useNetworkVariable("validator" as never);
  useImperativeHandle(ref, () => ({
    setOpen,
  }));
  const suiClient = useSuiClient();
  const { mutate: signAndExecute } = useSignAndExecuteTransaction({
    execute: async ({ bytes, signature }) =>
      await suiClient.executeTransactionBlock({
        transactionBlock: bytes,
        signature,
        options: {
          // Raw effects are required so the effects can be reported back to the wallet
          showRawEffects: true,
          showEffects: true,
          showEvents: true,
        },
      }),
  });
  const [dict, setDict] = useState<any>();
  const params = useParams();
  const lang = params.lang as string;
  useEffect(() => {
    getDictionary(lang).then(setDict);
  }, [lang]);

  // console.log("user in child = ", storeData);
  const onSignContract = async () => {
    // if (!account?.address) {
    //   messageApi.open({
    //     type: "warning",
    //     content: "请先连接钱包",
    //   });
    //   return;
    // }

    try {
      const txb = new Transaction();

      txb.setGasBudget(100000000 + parseInt(contract?.deposit + "" || "0"));
      const [coin] = txb.splitCoins(txb.gas, [contract?.deposit as number]);
      await new Promise(async (resolve, reject) => {
        txb.moveCall({
          target: `${PACKAGE_ID}::apply_for_adoption::sign_adopt_contract`,
          arguments: [
            txb.pure.id(contract?.contractAddress as string),
            txb.object(CONTRACTS_CONTAINER), // contracts
            coin,
            txb.object(SUI_SYSTEM_STATE_OBJECT_ID),
            txb.pure.address(validator), // validator
          ],
          typeArguments: [],
        });

        // Show loading state
        setLoading(true);

        signAndExecute(
          {
            transaction: txb as any,
          },
          {
            onSuccess: async (data) => {
              console.log("transaction digest: " + JSON.stringify(data));
              if ((data.effects && data.effects.status.status) === "success") {
                const res = await fetch(
                  `/api/petContracts/${contract?.documentId}?id=${contract?.documentId}`,
                  {
                    method: "PUT",
                    headers: {
                      "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                      data: {
                        state: "inProgress",
                        signDate: new Date().toISOString(),
                      },
                    }),
                  }
                );
                if (res && res.ok) {
                  resolve("");
                  messageApi.open({
                    type: "success",
                    content: dict?.My.transactionSucess // "交易成功",
                  });
                  setOpen(false);
                  onSuccess && onSuccess();
                } else {
                  reject(new Error(dict?.My.signContractFail + ": " + res.statusText));
                }
              } else {
                reject(new Error(dict?.My.transactionFail + ", digest: " + data.digest));
              }
            },
            onError: (err) => {
              console.error(dict?.My.transactionFail + ": " + err);
              reject(err);
            },
          }
        );
      });
    } catch (e: any) {
      messageApi.open({
        type: "error",
        content: e.message,
      });
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => {
    if (open) {
      setIsAgree(false);
    }
  }, [open]);

  return (
    <Modal
      title={<p>dict?.My.signContract</p>}
      open={open}
      maskClosable={false}
      onCancel={() => setOpen(false)}
      cancelText={dict?.My.cancel}
      // eslint-disable-next-line react/jsx-no-duplicate-props
      footer={(_, { OkBtn, CancelBtn }) => (
        <div className="flex justify-between items-center w-full">
          {contextHolder}
          <Checkbox
            checked={isAgree}
            onChange={(e) => {
              setIsAgree(e.target.checked);
            }}
          >
            {/* 已阅读条款并同意 */}
            {dict?.My.readAndAgree}
          </Checkbox>
          <Space>
            <Button
              type="primary"
              disabled={!isAgree}
              onClick={onSignContract}
              loading={loading}
            >
              {dict?.My.signContract}
            </Button>
            <CancelBtn />
          </Space>
        </div>
      )}
    >
      <section className="text-center">
        <h4 className="pb-3">{dict?.My.rules}</h4>
      </section>
      <section>
        <p className="mt-2">
          {dict?.My['r1-1']} &nbsp;
          <span className="text-red-500">
            {(contract && contract.deposit / SUI_MIST) || 0}
          </span>
          &nbsp;
          SUI，{dict?.My['r1-2']}
        </p>
        <p className="mt-2">
          {dict?.My['r2']}
        </p>
      </section>
    </Modal>
  );
};

export default forwardRef(SignContractModal);

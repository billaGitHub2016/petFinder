import { useState } from 'react';
import { Box, Button, Alert, Field } from '@strapi/design-system';
import { useSignAndExecuteTransaction, useSuiClient } from '@mysten/dapp-kit';
import { Transaction } from '@mysten/sui/transactions';
import {
    useFetchClient,
  } from '@strapi/strapi/admin';
export const SUI_MIST = 1000000000;

const CreateContractForm = ({ petApply }) => {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({
    type: 'success',
    msg: '',
  });
  const [deposit, setDeposit] = useState(0);
  const [recordTimes, setRecordTimes] = useState(0);
  const fetchClient = useFetchClient();

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

  const handleSubmit = async (e) => {
    // Prevent submitting parent form
    e.preventDefault();
    e.stopPropagation();

    try {
      const txb = new Transaction();

      txb.setGasBudget(100000000);
      console.log('!!!!!!petApply = ', petApply);
      await new Promise((resolve, reject) => {
        txb.moveCall({
          target: `0x3dd741554ec54ac85218c525d359b38118dc607be00e40d78877fc1cfab9da88::apply_for_adoption::create_adopt_contract`,
          arguments: [
            txb.pure.string(petApply.userId),
            txb.pure.string(petApply.documentId),
            txb.pure.u64(deposit * SUI_MIST),
            txb.pure.address(petApply.userWallet), // adopter_address
            txb.object('0xa6823bf196a9f709d5fcf53051e886d7bd839142a4d8cf7ad93898ba340fe719'), // contracts
            txb.pure.u64(recordTimes),
            txb.pure.u64(0),
          ],
          typeArguments: [],
        });

        // Show loading state
        setLoading(true);

        signAndExecute(
          {
            transaction: txb,
          },
          {
            onSuccess: async (data) => {
              console.log('transaction digest: ' + JSON.stringify(data));
              if ((data.effects && data.effects.status.status) === 'success') {
                const contractId =
                  data.events &&
                  Array.isArray(data.events) &&
                  data.events.length > 0 &&
                  data.events[0].parsedJson.contractId;

                const res = await fetchClient.post('/contract-strapi-plugin/contracts', {
                  contractId: '123',
                  userId: petApply.userId,
                  deposit,
                  recordTimes,
                  petId: petApply.documentId,
                  status: 'toSign',
                  address: petApply.adopterAddress,
                }); // 保存合约信息到数据库

                if (res.error) {
                  reject(new Error(res.error.message));
                } else {
                  resolve();
                }
              } else {
                const res = await fetchClient.post('/contract-strapi-plugin/contracts', {
                    contractAddress: '233',
                    contractsContainerAddress: '0xa6823bf196a9f709d5fcf53051e886d7bd839142a4d8cf7ad93898ba340fe719',
                    userId: petApply.userId,
                    deposit: deposit * SUI_MIST,
                    recordTimes: parseInt(recordTimes),
                    userWallet: petApply.userWallet,
                    state: 'toSign',
                    status: 'published',
                    pet: petApply.pet.documentId,
                  }); // 保存合约信息到数据库
  
                  if (res.error) {
                    reject(new Error(res.error.message));
                  } else {
                    resolve();
                  }
                // reject(new Error('交易失败: ' + data.digest));
              }
            },
            onError: (err) => {
              console.log('transaction error: ' + err);
              reject(err);
              // toast({
              //   title: "发布失败",
              //   description: `发布链上任务失败:${err.message}，请稍后再试`,
              //   variant: "destructive",
              // });
            },
          }
        );
      });

      setMessage({
        type: 'success',
        msg: '合同创建成功',
      });
    } catch (e) {
      console.error(e);
      setMessage({
        type: 'error',
        msg: e.message,
      });
    } finally {
      setLoading(false);
      setTimeout(() => {
        setMessage({
          type: 'success',
          msg: '',
        });
      }, 5000);
    }
  };
  return (
    <>
      {message.msg && (
        <Alert title="Tips" variant={message.type}>
          {message.msg}
        </Alert>
      )}
      <Box paddingTop={2} paddingBottom={2}>
        <Box paddingTop={2}>
          <Field.Root>
            <Field.Label>押金数量(SUI)</Field.Label>
            <Field.Input
              type="text"
              placeholder="填写押金(SUI)"
              onChange={(e) => setDeposit(e.target.value)}
              value={deposit}
            />
            <Field.Error />
          </Field.Root>
        </Box>
        <Box paddingTop={2}>
          <Field.Root>
            <Field.Label>回访次数</Field.Label>
            <Field.Input
              type="text"
              placeholder="填写回访次数"
              onChange={(e) => setRecordTimes(e.target.value)}
              value={recordTimes}
            />
            <Field.Error />
          </Field.Root>
        </Box>
      </Box>
      <Button type="submit" disabled={loading} onClick={handleSubmit}>
        {loading ? '提交中...' : '创建合同'}
      </Button>
    </>
  );
};

export default CreateContractForm;

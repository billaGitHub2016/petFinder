import { Main } from '@strapi/design-system';
import { useIntl } from 'react-intl';
import {
  ConnectButton,
  useCurrentAccount,
  useSignAndExecuteTransaction,
  useSuiClient,
} from '@mysten/dapp-kit';
import { useState } from 'react';
import { Transaction } from '@mysten/sui/transactions';
import {
  Box,
  Divider,
  Flex,
  TextButton,
  Typography,
  TextInput,
  Button,
  Alert,
  Field,
} from '@strapi/design-system';
import usePetApply from '../hooks/usePetApply';
import { getTranslation } from '../utils/getTranslation';
import { Providers } from '../components/providers/sui-provider';

const HomePage = () => {
  const { formatMessage } = useIntl();
  const { status, petApplies, refetchPetApplies } = usePetApply();
  const [deposit, setDeposit] = useState(0);
  const [recordTimes, setRecordTimes] = useState(0);

  console.log('petApplies', petApplies);

  const handleSubmit = async (e) => {
    // Prevent submitting parent form
    e.preventDefault();
    e.stopPropagation();

    const apply = petApplies[0]

    try {
      const txb = new Transaction();

      txb.setGasBudget(100000000);

      new Promise((resolve, reject) => {
        txb.moveCall({
          target: `0x3dd741554ec54ac85218c525d359b38118dc607be00e40d78877fc1cfab9da88::apply_for_adoption::create_adopt_contract`,
          arguments: [
            apply.userId,
            apply.pet.documentId,
            txb.pure.u64(deposit),
            txb.object(apply.userWallet), // adopter_address
            txb.object('0x3dd741554ec54ac85218c525d359b38118dc607be00e40d78877fc1cfab9da88::apply_for_adoption::AdoptContracts'), // contracts
            recordTimes,
            txb.pure.u64(0),
          ],
          typeArguments: [],
        });

        // Show loading state
        setStatus('loading');

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
                  contractId,
                  userId: apply.userId,
                  deposit,
                  recordTimes,
                  petId: apply.pet.documentId,
                  status: 0,
                  address: apply.adopterAddress,
                }); // 保存合约信息到数据库

                if (res.error) {
                  reject(res.error.message);
                } else {
                  resolve();
                }
              } else {
              }
            },
            onError: (err) => {
              console.log('transaction error: ' + err);
              // toast({
              //   title: "发布失败",
              //   description: `发布链上任务失败:${err.message}，请稍后再试`,
              //   variant: "destructive",
              // });
              setLoading(false);
            },
          }
        );
      });
    } catch (e) {
      setStatus('error');
    }
  };

  return (
    <Providers>
      {/* <Main> */}
      <Box
        aria-labelledy="additional-informations"
        background="neutral0"
        marginTop={4}
        width={'100%'}
      >
        <ConnectButton>连接钱包</ConnectButton>
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
        <Button type="submit" disabled={status === 'loading'} onClick={handleSubmit}>
          {status === 'loading' ? '提交中...' : '创建合同'}
        </Button>
      </Box>
      {/* </Main> */}
    </Providers>
  );
};

export { HomePage };

import { Main } from '@strapi/design-system';
import { useIntl } from 'react-intl';
import {
  ConnectButton,
  useCurrentAccount,
  useSignAndExecuteTransaction,
  useSuiClient,
} from '@mysten/dapp-kit';
import { useState } from 'react';
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
import CreateContractForm from '../components/providers/CreateContractForm';

const HomePage = () => {
  const { formatMessage } = useIntl();
  const { status, petApplies, refetchPetApplies, model } = usePetApply();
  console.log('model = ', model);
  return (
    <Providers>
      <Box
        aria-labelledy="additional-informations"
        background="neutral0"
        marginTop={4}
        width={'100%'}
      >
        {model === 'api::pet-apply.pet-apply' && (
          <>
            <ConnectButton>连接钱包</ConnectButton>
            <CreateContractForm petApply={petApplies} />
          </>
        )}
      </Box>
    </Providers>
  );
};

export { HomePage };

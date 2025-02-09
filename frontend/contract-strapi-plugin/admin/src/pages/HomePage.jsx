import { Main } from '@strapi/design-system';
import { useIntl } from 'react-intl';

import { getTranslation } from '../utils/getTranslation';
import { Providers } from "../components/providers/sui-provider";
import {
  ConnectButton,
  useCurrentAccount,
  useSignAndExecuteTransaction,
  useSuiClient,
} from "@mysten/dapp-kit";

import usePetApply from '../hooks/usePetApply'

const HomePage = () => {
  const { formatMessage } = useIntl();

  return (
    <Providers>
      <Main>
      <ConnectButton>连接钱包</ConnectButton>
        <span>123</span>
        <button>111</button>
        <h1>Welcome to {formatMessage({ id: getTranslation('haha2') })}</h1>
      </Main>
    </Providers>
  );
};

export { HomePage };

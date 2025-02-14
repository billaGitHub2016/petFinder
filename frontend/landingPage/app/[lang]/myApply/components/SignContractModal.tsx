import { Button, Modal, Checkbox, message } from "antd";
import type { CheckboxProps } from 'antd';
import {
  forwardRef,
  Ref,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
  useContext,
} from "react";
import { useCurrentAccount } from "@mysten/dapp-kit";
import type { DataType as Contract} from './Contracts';
import { SUI_MIST } from "@/config/constants";

const SignContractModal = (
  {
    contract
  }: {
    contract?: Contract | null
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
  useImperativeHandle(ref, () => ({
    setOpen,
  }));
  // console.log("user in child = ", storeData);
  const onSignContract = () => {
    if (!account) {
      messageApi.open({
        type: "warning",
        content: "请先连接钱包",
      });
      return;
    }

  }
  useEffect(() => {
    if (open) {
      setIsAgree(false)
    }
  }, [open])

  return (
    <Modal
      title={<p>签署合同</p>}
      loading={loading}
      open={open}
      maskClosable={false}
      onCancel={() => setOpen(false)}
      // eslint-disable-next-line react/jsx-no-duplicate-props
      footer={(_, { OkBtn, CancelBtn }) => (
        <>
          <Button disabled={!isAgree} onClick={onSignContract}>签约</Button>
          <CancelBtn />
          <Checkbox checked={isAgree} onChange={(e) => {
            setIsAgree(e.target.checked)
          }} />
        </>
      )}
    >
      <section className="text-center">
        <h3>领养协议条款</h3>
      </section>
      <section>
        <p>1. 领养人将支付 <span className="text-red-500">{ (contract && (contract.deposit / SUI_MIST)) || 0}</span>SUI，作为押金。押金和产生的利息将根据回访结果结果返还，返还规则：全部回访通过，则返还全部押金，否则按通过比例返还。</p>
        <p>2. 如果有恶意弃养动物的情况，则不退还押金，并会在社交平台曝光弃养行为。</p>
      </section>  
    </Modal>
  );
};

export default forwardRef(SignContractModal);

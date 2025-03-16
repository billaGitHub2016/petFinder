import { Button, Modal, Form, Input, Radio, Checkbox, FormProps, message } from "antd";
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
import { AppStoreContext } from "@/components/AppStoreProvider";
import type { PetCardProps } from "./PetCard";
import { getDictionary } from "@/lib/i18n";
import { useParams } from "next/navigation";

type LayoutType = Parameters<typeof Form>[0]["layout"];

type FieldType = {
  health?: string;
  experience?: string;
  selfStatus?: string;
  bugget?: string;
};

const AdoptApplyModal = (
  {
    animalInfo,
  }: {
    animalInfo: PetCardProps | null;
  },
  ref: Ref<{
    setOpen: Function;
  }>
) => {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  useImperativeHandle(ref, () => ({
    setOpen,
  }));
  const [form] = Form.useForm();
  const [formLayout, setFormLayout] = useState<LayoutType>("vertical");
  const { user } = useContext(AppStoreContext) as any;
  const [messageApi, contextHolder] = message.useMessage();
  const account = useCurrentAccount();

  const [dict, setDict] = useState<any>();
  const params = useParams();
  const lang = params.lang as string;

  useEffect(() => {
    getDictionary(lang).then(setDict);
  }, [lang]);

  const createApply = async (params: any) => {
    const response = await fetch(`/api/petApply`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(params),
    });
    if (!response.ok) {
      throw new Error(dict?.AdoptionCenter.submitApplyFail || "提交申请失败");
    }
    const result = await response.json();
    return result.data;
  }

  const onSubmit: FormProps<FieldType>["onFinish"] = (values) => {
    // console.log("Success:", values);
    // console.log("user = ", user);
    setLoading(true)
    createApply({
      data: {
        ...values,
        userId: user.email,
        pet: { connect: animalInfo && animalInfo.documentId },
        health: (values.health as unknown as string[])?.join(","),
        state: 'InReview',
        userWallet: account?.address
      },
      statue: 'published'
    })
      .then(() => {
        messageApi.open({
          type: "success",
          content: dict.AdoptionCenter.submitApplySuccess // "提交申请成功",
        })
        form.resetFields();
        setOpen(false);
      })
      .catch((error) => {
        messageApi.open({
          type: "error",
          content: "提交申请失败：" + error.message,
        })
      })
      .finally(() => {
        setLoading(false)
      });
  };

  const healthOptions = [
    { label: dict?.AdoptionCenter.health, value: "健康" },
    { label: dict?.AdoptionCenter.disability, value: "存在残疾" },
    { label: dict?.AdoptionCenter.chronicDiseases, value: "患有慢性病" },
  ];
  const experienceOptions = [
    { label: dict?.AdoptionCenter.oneMore, value: "现在有，想再领养一只" },
    { label: dict?.AdoptionCenter.oneBefore, value: "过去有，已经过世" },
    { label: dict?.AdoptionCenter.oneLost, value: "过去有，后来走丢了" },
    { label: dict?.AdoptionCenter.noBefore, value: "没有养过" },
    { label: dict?.AdoptionCenter.oneGive, value: "宠物送人/放生了" },
  ];
  const statusOptions = [
    { label: dict?.AdoptionCenter.student, value: "在校学生" },
    { label: dict?.AdoptionCenter.worker, value: "在职人员" },
    { label: dict?.AdoptionCenter.retire, value: "离职人员" },
    { label: dict?.AdoptionCenter.unemployed, value: "退休人员" },
  ];
  const buggetOptions = [
    { label: dict?.AdoptionCenter['500'], value: "500-700" },
    { label: dict?.AdoptionCenter['700'], value: "700-1000" },
    { label: dict?.AdoptionCenter['1000'], value: "1000-1500" },
    { label: dict?.AdoptionCenter['1500'], value: "1500以上" },
  ];

  return (
    <Modal
      title={<p>{dict?.AdoptionCenter.fillForm}</p>}
      open={open}
      footer={null}
      width="700px"
      maskClosable={false}
      onCancel={() => setOpen(false)}
    >
      {contextHolder}
      <div className="p-2">
        <Form
          layout={formLayout}
          form={form}
          initialValues={{ layout: formLayout }}
          style={{ maxWidth: formLayout === "inline" ? "none" : 600 }}
          onFinish={onSubmit}
        >
          <div className="pb-4">
            <Form.Item
              label={dict?.AdoptionCenter.healthStatus}
              name="health"
              rules={[{ required: true, message: dict?.AdoptionCenter.isRequired }]}
            >
              <Checkbox.Group options={healthOptions} defaultValue={[]} />
            </Form.Item>
          </div>
          <div className="pb-4">
            <Form.Item
              label={dict?.AdoptionCenter.hasPetBefore}
              name="experience"
              rules={[{ required: true, message: dict?.AdoptionCenter.isRequired }]}
            >
              <Radio.Group options={experienceOptions} />
            </Form.Item>
          </div>
          <div className="pb-4">
            <Form.Item
              label={dict?.AdoptionCenter.identify}
              name="selfStatus"
              rules={[{ required: true, message: dict?.AdoptionCenter.isRequired }]}
            >
              <Radio.Group options={statusOptions} />
            </Form.Item>
          </div>
          <div className="pb-4">
            <Form.Item
              label={dict?.AdoptionCenter.bugget}
              name="bugget"
              rules={[{ required: true, message: dict?.AdoptionCenter.isRequired }]}
            >
              <Radio.Group options={buggetOptions} />
            </Form.Item>
          </div>
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={loading}>
              {dict?.AdoptionCenter.submit}
            </Button>
          </Form.Item>
        </Form>
      </div>
    </Modal>
  );
};

export default forwardRef(AdoptApplyModal);

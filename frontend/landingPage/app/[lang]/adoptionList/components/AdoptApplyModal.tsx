import { Button, Modal, Form, Input, Radio, Checkbox, FormProps } from "antd";
import {
  forwardRef,
  Ref,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
  useContext,
} from "react";
import { AppStoreContext } from "@/components/AppStoreProvider";

type LayoutType = Parameters<typeof Form>[0]["layout"];

type FieldType = {
  health?: string;
  experience?: string;
  status?: string;
  bugget?: string;
};

const AdoptApplyModal = (
  {}: {},
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

  const onSubmit: FormProps<FieldType>["onFinish"] = (values) => {
    console.log("Success:", values);
    console.log('user = ', user)
    form.resetFields();
    setOpen(false)
  };

  const healthOptions = [
    { label: "健康", value: "1" },
    { label: "存在残疾", value: "2" },
    { label: "患有慢性病", value: "3" },
  ];
  const experienceOptions = [
    { label: "现在有，想再领养一只", value: "1" },
    { label: "过去有，已经过世", value: "2" },
    { label: "过去有，后来走丢了", value: "3" },
    { label: "没有养过", value: "4" },
    { label: "宠物送人/放生了", value: "5" },
  ];
  const statusOptions = [
    { label: "在校学生", value: "1" },
    { label: "在职人员", value: "2" },
    { label: "离职人员", value: "3" },
    { label: "退休人员", value: "4" },
  ];
  const buggetOptions = [
    { label: "500元-700元", value: "1" },
    { label: "700元-1000元", value: "2" },
    { label: "1000元-1500元", value: "3" },
    { label: "1500元以上", value: "4" },
  ];

  return (
    <Modal
      title={<p>填写申请表</p>}
      loading={loading}
      open={open}
      footer={null}
      width="700px"
      maskClosable={false}
      onCancel={() => setOpen(false)}
    >
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
              label="您能接受领养动物的健康状况为(多选)"
              name="health"
              rules={[{ required: true, message: "请填写必填项" }]}
              
            >
              <Checkbox.Group options={healthOptions} defaultValue={[]} />
            </Form.Item>
          </div>
          <div className="pb-4">
            <Form.Item
              label="过去是否有养宠经验"
              name="experience"
              rules={[{ required: true, message: "请填写必填项" }]}
            >
              <Radio.Group options={experienceOptions} />
            </Form.Item>
          </div>
          <div className="pb-4">
            <Form.Item
              label="您目前的身份"
              name="status"
              rules={[{ required: true, message: "请填写必填项" }]}
            >
              <Radio.Group options={statusOptions} />
            </Form.Item>
          </div>
          <div className="pb-4">
            <Form.Item
              label="您的养宠预算为(元/月 不计算疫苗零食玩具绝育等额外费用)"
              name="bugget"
              rules={[{ required: true, message: "请填写必填项" }]}
            >
              <Radio.Group options={buggetOptions} />
            </Form.Item>
          </div>
          <Form.Item>
            <Button type="primary" htmlType="submit">
              Submit
            </Button>
          </Form.Item>
        </Form>
      </div>
    </Modal>
  );
};

export default forwardRef(AdoptApplyModal);

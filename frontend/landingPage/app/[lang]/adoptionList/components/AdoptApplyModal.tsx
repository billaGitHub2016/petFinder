import { Button, Modal, Form, Input, Radio, Checkbox } from "antd";
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

  const healthOptions = [
    { label: '健康', value: '1' },
    { label: '存在残疾', value: '2' },
    { label: '患有慢性病', value: '3' },
  ]
  const experienceOptions = [
    { label: '现在有，想再领养一只', value: '1' },
    { label: '过去有，已经过世', value: '2' },
    { label: '过去有，后来走丢了', value: '3' },
    { label: '没有养过', value: '4' },
    { label: '宠物送人/放生了', value: '5' },
  ]

  return (
    <Modal
      title={<p>填写申请表</p>}
      loading={loading}
      open={open}
      footer={null}
      maskClosable={false}
      onCancel={() => setOpen(false)}
    >
      <div
        className="relative"
      >
        <Form
          layout={formLayout}
          form={form}
          initialValues={{ layout: formLayout }}
          style={{ maxWidth: formLayout === "inline" ? "none" : 600 }}
        >
          <Form.Item label="您能接受领养动物的健康状况为(多选)" name="health" required>
            <Checkbox.Group options={healthOptions} defaultValue={[]} />
          </Form.Item>
          <Form.Item label="过去是否有养宠经验" name="experience" required>
            <Radio.Group options={experienceOptions} />
          </Form.Item>
          <Form.Item>
            <Button type="primary">Submit</Button>
          </Form.Item>
        </Form>
      </div>
    </Modal>
  );
};

export default forwardRef(AdoptApplyModal);

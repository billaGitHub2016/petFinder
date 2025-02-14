import { Button, Modal, Checkbox, message, Upload, Form, Input  } from "antd";
import { UploadOutlined } from '@ant-design/icons';
import type { UploadFile, UploadProps } from 'antd';
import {
  forwardRef,
  Ref,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from "react";
import { useCurrentAccount } from "@mysten/dapp-kit";
import type { DataType as Record} from './Records';

type FieldType = {
  submitText?: string;
};

const { TextArea } = Input;

const SubmitRecordModal = (
  {
    record
  }: {
    record?: Record | null
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
  const [fileList, setFileList] = useState<UploadFile[]>([
    {
      uid: '-1',
      name: 'xxx.png',
      status: 'done',
      url: 'http://www.baidu.com/xxx.png',
    },
  ]);
  useImperativeHandle(ref, () => ({
    setOpen,
  }));

  const [form] = Form.useForm();

  const onSubmit = () => {
    if (!account) {
      messageApi.open({
        type: "warning",
        content: "请先连接钱包",
      });
      return;
    }
    form.validateFields().then(async () => {
      console.log('form value = ', form.getFieldsValue())
      const response = await fetch(`/api/records`, {
        method: 'PUT',
        body: JSON.stringify({
          id: record?.id,
          imgs: fileList.map(item => item.id),
          state: 'submited'
        })
      });
      if (!response.ok) {
        // throw new Error("提交回访记录失败");
        messageApi.open({
          type: "error",
          content: "提交回访记录失败",
        });
        return;
      }
      messageApi.open({
        type: "success",
        content: "提交成功"
      })
      setOpen(false)
    })
  }
  useEffect(() => {
    if (open) {
      setIsAgree(false)
    }
  }, [open])

  const handleChange: UploadProps['onChange'] = (info) => {
    let newFileList = [...info.fileList];
    // 2. Read from response and show file link
    newFileList = newFileList.map((file) => {
      if (file.response) {
        // Component will show file.url as link
        file.url = file.response.url;
      }
      return file;
    });

    setFileList(newFileList);
  };

  return (
    <Modal
      title={<p>提交回访记录</p>}
      loading={loading}
      open={open}
      maskClosable={false}
      onCancel={() => setOpen(false)}
      onOk={onSubmit}
    >
      <Upload
        action="/api/upload"
        listType="picture"
        defaultFileList={fileList}
        onChange={handleChange}
      >
        <Button type="primary" icon={<UploadOutlined />}>
          Upload
        </Button>
      </Upload>

      <Form
        name="basic"
        labelCol={{ span: 8 }}
        wrapperCol={{ span: 16 }}
        style={{ maxWidth: 600 }}
        initialValues={{ }}
        autoComplete="off"
      >
        <Form.Item<FieldType>
          label="描述"
          name="submitText"
          rules={[{ required: true, message: '请输入描述信息' }]}
        >
          <TextArea rows={4} />
        </Form.Item>

      </Form>      
    </Modal>
  );
};

export default forwardRef(SubmitRecordModal);

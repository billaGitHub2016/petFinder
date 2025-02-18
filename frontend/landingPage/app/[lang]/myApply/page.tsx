"use client";
import { useContext } from "react";
import { redirect } from "next/navigation";
import { Tabs, Modal } from "antd";
import type { TabsProps } from "antd";
import { ExclamationCircleFilled } from "@ant-design/icons";
import { AppStoreContext } from "@/components/AppStoreProvider";
import Applies from "./components/Applies";
import Contracts from "./components/Contracts";
import Records from "./components/Records";

const { confirm } = Modal;

const items: TabsProps["items"] = [
  {
    key: "1",
    label: "我的申请",
    children: <Applies />,
  },
  {
    key: "2",
    label: "我的合同",
    children: <Contracts></Contracts>,
  },
  {
    key: "3",
    label: "回访记录",
    children: <Records></Records>,
  },
];

export default function MyApply() {
  const storeData: any = useContext(AppStoreContext);

    if (!storeData.user) {
      redirect("/zh/login");
    }

  // if (!storeData.user) {
  //   confirm({
  //     title: "提示",
  //     icon: <ExclamationCircleFilled />,
  //     content: "请先登录",
  //     okText: "去登录",
  //     cancelButtonProps: { style: { display: "none" } },
  //     onOk() {
  //       console.log('ok')
  //       redirect("/zh/login");
  //     },
  //     onCancel() {},
  //   });
  //   return;
  // }

  const onChange = (key: string) => {
    console.log(key);
  };

  return (
    <div className="w-full max-w-7xl px-4 sm:px-6 lg:px-8 pb-16 pt-16 md:pt-4">
      <Tabs
        defaultActiveKey="1"
        items={items}
        onChange={onChange}
        size="large"
      />
    </div>
  );
}

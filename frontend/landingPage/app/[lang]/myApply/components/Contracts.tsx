"use client";
import { useContext } from "react";
import { Table, Tag } from "antd";
import type { TableProps } from "antd";
import { AppStoreContext } from "@/components/AppStoreProvider";

interface DataType {
  id: string;
  petName: string;
  date: string;
  deposit: number;
  count: string;
  state: string;
}

const columns: TableProps<DataType>["columns"] = [
  {
    title: "合同编号",
    dataIndex: "id",
    key: "id",
  },
  {
    title: "宠物名",
    dataIndex: "petName",
    key: "petName",
    render: (text) => <a>{text}</a>,
  },
  {
    title: "押金(SUI)",
    dataIndex: "deposit",
    key: "deposit",
  },
  {
    title: "回访总数",
    dataIndex: "count",
    key: "count",
  },
  {
    title: "签署日期",
    dataIndex: "date",
    key: "date",
  },
  {
    title: "合同状态",
    dataIndex: "state",
    key: "state",
    render: (_, { state }) => {
      let color = "geekblue";
      if (state === "进行中") {
        color = "cyan";
      } else if (state === "已完成") {
        color = "green";
      } else if (state === "中止") {
        color = "volcano";
      }
      return (
        <>
          <Tag color={color}>{state}</Tag>
        </>
      );
    },
  },
];

const data: DataType[] = [
  {
    id: "1",
    petName: "小黑",
    deposit: 1,
    count: "3",
    date: "2025-02-11 19:00",
    state: "进行中",
  },
];
const Contracts = () => {
  const storeData: any = useContext(AppStoreContext);

  return (
    <div>
      <Table<DataType>
        columns={columns}
        dataSource={data}
        pagination={{ position: ["none"] }}
      />
    </div>
  );
};

export default Contracts;

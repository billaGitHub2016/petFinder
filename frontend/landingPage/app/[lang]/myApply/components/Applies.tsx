"use client";
import { useContext } from "react";
import { Table, Tag } from "antd";
import type { TableProps } from "antd";
import { AppStoreContext } from "@/components/AppStoreProvider";

interface DataType {
  id: string;
  petName: string;
  date: string;
  state: string;
}

const columns: TableProps<DataType>["columns"] = [
  {
    title: "申请编号",
    dataIndex: "id",
    key: "id",
  },
  {
    title: "宠物名",
    dataIndex: "age",
    key: "age",
    render: (text) => <a>{text}</a>,
  },
  {
    title: "申请日期",
    dataIndex: "date",
    key: "date",
  },
  {
    title: "审核状态",
    dataIndex: "state",
    key: "state",
    render: (_, { state }) => {
      let color = "geekblue";
      if (state === "审核中") {
        color = "cyan";
      } else if (state === "审核通过") {
        color = "green";
      } else if (state === "审核未通过") {
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
    date: "2025-02-11 19:00",
    state: "审核中",
  },
];
const Applies = () => {
  const storeData: any = useContext(AppStoreContext);

  return (
    <div>
      <Table<DataType> columns={columns} dataSource={data} pagination={{ position: ['none'] }}/>
    </div>
  );
};

export default Applies;

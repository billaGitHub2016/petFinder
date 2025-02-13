"use client";
import { useContext, useEffect, useState } from "react";
import { Table, Tag } from "antd";
import type { TableProps } from "antd";
import { AppStoreContext } from "@/components/AppStoreProvider";
import qs from "qs";

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
    dataIndex: "recordTimes",
    key: "recordTimes",
  },
  {
    title: "签署日期",
    dataIndex: "createdAt",
    key: "createdAt",
  },
  {
    title: "合同状态",
    dataIndex: "state",
    key: "state",
    render: (_, { state }) => {
      const stateMap: { [key: string]: string } = {
        toSign: "待签署",
        complete: "已完成",
        termination: "已终止",
        inProgress: "进行中",
      };
      let color = "geekblue";
      if (state === "toSign") {
        color = "cyan";
      } else if (state === "complete") {
        color = "green";
      } else if (state === "termination") {
        color = "volcano";
      }
      return (
        <>
          <Tag color={color}>{stateMap[state]}</Tag>
        </>
      );
    },
  },
];

// const data: DataType[] = [
//   {
//     id: "1",
//     petName: "小黑",
//     deposit: 1,
//     count: "3",
//     date: "2025-02-11 19:00",
//     state: "进行中",
//   },
// ];

async function fetchContracts({ userId }: { userId: string }) {
  const query = qs.stringify(
    {
      filters: {
        userId: {
          $eq: userId,
        },
      },
      populate: 'pet',
      pagination: {
        page: 1,
        pageSize: 100,
      },
    },
    {
      encodeValuesOnly: true, // prettify URL
    }
  );
  const response = await fetch(`/api/petContracts?${query}`);
  if (!response.ok) {
    throw new Error("Failed to fetch contracts");
  }
  const result = await response.json();
  return result.data?.data?.map((item: any) => ({
    ...item,
    petName: item.pet.petName,
  }));
}

const Contracts = () => {
  const storeData: any = useContext(AppStoreContext);
  const [data, setData] = useState<DataType[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    setLoading(true);
    fetchContracts({ userId: storeData.user.email })
      .then((res) => {
        console.log('res = ', res);
        setData(res);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  return (
    <div>
      <Table<DataType>
        loading={loading}
        columns={columns}
        dataSource={data}
        pagination={{ position: ["none"] }}
      />
    </div>
  );
};

export default Contracts;

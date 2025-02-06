import { Button, Modal, Carousel } from "antd";
import {
  forwardRef,
  Ref,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from "react";
import Image from "next/image";
import type { PetCardProps } from "./PetCard";
import PetInfoBlock from './PetInfoBlock'

const PetDetailModal = (
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
  const imgArray = (animalInfo && animalInfo.imgs && animalInfo.imgs.split(",")) || [];

  const contentStyle: React.CSSProperties = {
    margin: 0,
    height: "160px",
    color: "#fff",
    lineHeight: "160px",
    textAlign: "center",
    background: "#364d79",
  };

  return (
    <Modal
      title={<p>Loading Modal</p>}
      loading={loading}
      open={open}
      footer={null}
      maskClosable={false}
      onCancel={() => setOpen(false)}
    >
      <Carousel arrows infinite={true} autoplay>
        {imgArray.map((img, i) => {
          return (
            <div className="h-96 w-60" key={i}>
              {/* <Image src={img} alt={""} fill/> */}
              <img src={img} alt={""} className="object-scale-down" />
            </div>
          );
        })}
      </Carousel>
      <div className="mt-3 flex justify-center">
        <div className="grid grid-cols-4 place-items-center gap-3 w-4/5">
            <PetInfoBlock type="age" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="weight" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="hairType" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="hairLength" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="ageType" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="isDeworm" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="isNeuter" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="isVaccine" animalInfo={animalInfo}></PetInfoBlock>
        </div>
      </div>
      <div className="mt-5">
        <p className="font-bold text-lg mb-3">
            详细信息
        </p>
        <div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">宠物状态</div>
                <div>{animalInfo && animalInfo.adoptStatus}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">发布时间</div>
                <div>{animalInfo && animalInfo.infoUpdateTime}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">性格</div>
                <div>{animalInfo && animalInfo.characterDescription}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">是否接受合租</div>
                <div>{animalInfo && animalInfo.adoptConditions}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">宠物所在地址</div>
                <div>{animalInfo && animalInfo.address}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">领养地址要求</div>
                <div>{animalInfo && animalInfo.adoptNeedAddress.split(',').filter(item => item !== '无').join('·')}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">TA的简介</div>
                <div>{animalInfo && animalInfo.petDescription}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-2">
                <div className="text-gray-600">救助史</div>
                <div>{animalInfo && animalInfo.sourceRemark}</div>
            </div>
        </div>
      </div>
    </Modal>
  );
};

export default forwardRef(PetDetailModal);

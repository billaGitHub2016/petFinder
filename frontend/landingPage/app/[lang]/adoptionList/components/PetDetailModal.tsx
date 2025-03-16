import { Button, Modal, Carousel } from "antd";
import {
  forwardRef,
  Ref,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
  useContext,
} from "react";
import Image from "next/image";
import { Dog, Cat, Share2 } from "lucide-react";
import type { PetCardProps } from "./PetCard";
import PetInfoBlock from "./PetInfoBlock";
import { AppStoreContext } from "@/components/AppStoreProvider";
import Link from "next/link";
import { useParams } from "next/navigation";
import { getDictionary } from "@/lib/i18n";

const PetDetailModal = (
  {
    animalInfo,
    onAdopt,
    hasButton = true
  }: {
    animalInfo: PetCardProps | null;
    onAdopt?: () => void;
    hasButton?: boolean;
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
  const imgArray =
    (animalInfo && animalInfo.imgs && animalInfo.imgs.split(",")) || [];
  const storeData = useContext(AppStoreContext);
  const [dict, setDict] = useState<any>();
  const params = useParams();
  const lang = params.lang as string;

  useEffect(() => {
    getDictionary(lang).then(setDict);
  }, [lang]);
  // console.log("user in child = ", storeData);

  return (
    <Modal
      title={<p>{dict?.AdoptionCenter.petDetail}</p>}
      loading={loading}
      open={open}
      footer={null}
      maskClosable={false}
      onCancel={() => setOpen(false)}
    >
      <div
        style={{ height: "75vh" }}
        className="overflow-y-scroll relative pb-16"
      >
        <Carousel arrows infinite={true} autoplay draggable={true}>
          {imgArray.map((img, i) => {
            return (
              <div className="h-96 bg-gray-200" key={i}>
                {/* <Link href={img} target="_blank" rel="noreferrer">
                  <Image src={img} alt={""} fill/>
                </Link> */}
                <a href={img} target="_blank" rel="noreferrer">
                  <img src={img} alt={""} className="object-fill" />
                </a>
              </div>
            );
          })}
        </Carousel>
        <div className="flex items-center justify-start mt-4">
          <h3 className="text-lg text-gray-900 mb-0 mr-2">
            {animalInfo && animalInfo.petName}
          </h3>
          {animalInfo && animalInfo.petType === "dog" && (
            <Dog className="mr-2 h-8" />
          )}
          {animalInfo && animalInfo.petType === "cat" && (
            <Cat className="mr-2 h-8" />
          )}
          {animalInfo && animalInfo.sex === 1 && (
            <Image src="/icons/male.svg" width={20} height={20} alt="公" />
          )}
          {animalInfo && animalInfo.sex === 2 && (
            <Image src="/icons/female.svg" width={20} height={20} alt="母" />
          )}
          {/* {animalInfo.adoptNeedAddress && (
            <span className="text-xs px-2 py-1 bg-orange-100 text-[hsl(24.6,95%,53.1%)] rounded-full">{animalInfo.adoptNeedAddress}</span>
          )} */}
        </div>
        <div className="mt-3 flex justify-center">
          <div className="grid grid-cols-4 place-items-center gap-3 w-4/5">
            <PetInfoBlock type="age" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock type="weight" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock
              type="hairType"
              animalInfo={animalInfo}
            ></PetInfoBlock>
            <PetInfoBlock
              type="hairLength"
              animalInfo={animalInfo}
            ></PetInfoBlock>
            <PetInfoBlock type="ageType" animalInfo={animalInfo}></PetInfoBlock>
            <PetInfoBlock
              type="isDeworm"
              animalInfo={animalInfo}
            ></PetInfoBlock>
            <PetInfoBlock
              type="isNeuter"
              animalInfo={animalInfo}
            ></PetInfoBlock>
            <PetInfoBlock
              type="isVaccine"
              animalInfo={animalInfo}
            ></PetInfoBlock>
          </div>
        </div>
        <div className="mt-5">
          <p className="font-bold text-lg mb-3">{dict?.AdoptionCenter.detailInfo}</p>
          <div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.petStatus}</div>
              <div>{animalInfo && animalInfo.adoptStatus}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.publishDate}</div>
              <div>{animalInfo && new Date(animalInfo.infoUpdateTime).toLocaleString()}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.character}</div>
              <div>{animalInfo && animalInfo.characterDescription}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.sharedRental}</div>
              <div>{animalInfo && animalInfo.isShared === 0 ? dict?.AdoptionCenter.noAccept : dict?.AdoptionCenter.accept}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.petAddress}</div>
              <div>{animalInfo && animalInfo.address}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.addressRequired}</div>
              <div>
                {animalInfo &&
                  animalInfo.adoptNeedAddress
                    .split(",")
                    .filter((item) => item !== "无")
                    .join("·")}
              </div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.sumary}</div>
              <div>{animalInfo && animalInfo.petDescription}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.condition}</div>
              <div>{animalInfo && animalInfo.adoptConditions}</div>
            </div>
            <div className="grid grid-cols-[25%_1fr] text-base mb-3">
              <div className="text-gray-600">{dict?.AdoptionCenter.story}</div>
              <div>{animalInfo && animalInfo.sourceRemark}</div>
            </div>
          </div>
        </div>
      </div>

      { hasButton && (<div className="absolute bottom-0 left-0 w-full">
        <AdoptButtonGroup onAdopt={onAdopt} dict={dict}></AdoptButtonGroup>
      </div>)}
    </Modal>
  );
};

const AdoptButtonGroup = ({
  onAdopt,
  dict
}: {
  onAdopt?: () => void;
  dict?: any;
}) => {
  return (
    <div className="flex justify-between items-center w-full pt-1 pb-1 px-6 border-t-1 border-neutral-200 bg-white">
      <div className="flex flex-col items-center gap-1 text-gray-400 cursor-pointer">
        <Share2 />
        <span className="text-black">{dict?.AdoptionCenter.share}</span>
      </div>
      <Button type="primary" size="large" shape="round" onClick={onAdopt}>
      {dict?.AdoptionCenter.applyAdoption}
      </Button>
    </div>
  );
};

export default forwardRef(PetDetailModal);

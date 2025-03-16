import {
  Cake,
  Weight,
  Feather,
  Ruler,
  Baby,
  Bug,
  Scissors,
  Syringe,
} from "lucide-react";

import type { PetCardProps } from "./PetCard";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { getDictionary } from "@/lib/i18n";

const PetInfoBlock = ({
  animalInfo,
  type,
}: {
  animalInfo: PetCardProps | null;
  type:
    | "age"
    | "weight"
    | "hairType"
    | "hairLength"
    | "ageType"
    | "isDeworm"
    | "isNeuter"
    | "isVaccine";
}) => {
  const [dict, setDict] = useState<any>();
  const params = useParams();
  const lang = params.lang as string;

  useEffect(() => {
    getDictionary(lang).then(setDict);
  }, [lang]);
  return (
    <div className="flex flex-col items-center justify-center bg-slate-200 rounded-sm pt-2 text-gray-700 w-20 h-20">
      {type === "age" && (
        <>
          <Cake className="mb-1"></Cake>
          <span>
            {mounthsToYear((animalInfo && animalInfo.ageMonth) || 0)}{dict?.AdoptionCenter.years}
          </span>
        </>
      )}
      {type === "weight" && (
        <>
          <Weight className="mb-1"></Weight>
          <span>
            {animalInfo && parseFloat(animalInfo.weight).toFixed(1)}kg
          </span>
        </>
      )}
      {type === "hairType" && (
        <>
          <Feather className="mb-1"></Feather>
          <span>{animalInfo && animalInfo.hairType}</span>
        </>
      )}
      {type === "hairLength" && (
        <>
          <Ruler className="mb-1"></Ruler>
          <span>{animalInfo && animalInfo.hairLength}</span>
        </>
      )}
      {type === "ageType" && (
        <>
          <Baby className="mb-1"></Baby>
          <span>{animalInfo && animalInfo.ageType}</span>
        </>
      )}
      {type === "isDeworm" && (
        <>
          <Bug className="mb-1"></Bug>
          <span className="text-center">
            {animalInfo && animalInfo.isDeworm === 1 ? dict?.AdoptionCenter.dewormed : dict?.AdoptionCenter.notDewormed}
          </span>
        </>
      )}
      {type === "isNeuter" && (
        <>
          <Scissors className="mb-1"></Scissors>
          <span className="text-center">
            {animalInfo && animalInfo.isNeuter === 1 ? dict?.AdoptionCenter.sterilized : dict?.AdoptionCenter.notSterilized}
          </span>
        </>
      )}
      {type === "isVaccine" && (
        <>
          <Syringe className="mb-1"></Syringe>
          <span className="text-center">
            {animalInfo && animalInfo.isVaccine === 1 ? dict?.AdoptionCenter.vaccinated : dict?.AdoptionCenter.notVaccinated}
          </span>
        </>
      )}
    </div>
  );
};

function mounthsToYear(mounths: number) {
  return (mounths / 12).toFixed(1);
}

export default PetInfoBlock;

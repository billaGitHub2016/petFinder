"use client";
import { useState, useEffect, useRef } from "react";
import Image from "next/image";
import { TestimonialsData } from "@/config/testimonials";
import Link from "next/link";
import { TwitterX } from "@/components/social-icons/icons";
import Filter from "./Filter";
import PetCard, { PetCardProps } from "./PetCard";
import pets from "@/raw-datas/1.json";
import PetDetailModal from "./PetDetailModal";

async function fetchPets() {
  const response = await fetch(`/api/pets`);
  if (!response.ok) {
    throw new Error("Failed to fetch pets");
  }
  const result = await response.json();
  return result.data;
}
export function PetList() {
  const detailModal = useRef<{ setOpen: Function }>(null);

  useEffect(() => {
    // fetchPets().then((pets) => {
    //     // setTask(t);
    //     console.log('fetch pets = ', pets)
    // })
    //     .finally(() => {
    //     });;
  });

  const onSearch = (searchTerm: string) => {
    console.log(searchTerm);
  };

  const [curPet, setCurPet] = useState(null);
  const onPetClick = (pet: PetCardProps) => {
    console.log("click pet = ", pet);
    detailModal.current?.setOpen(true);
    setCurPet(pet);
  };

  return (
    <div className="flex flex-col justify-center items-center w-5/6">
      <div className="flex justify-start items-center mb-4 w-full">
        <Filter searchCallback={onSearch}></Filter>
      </div>
      <div className="columns-1 sm:columns-2 lg:columns-3 xl:columns-4 gap-4 overflow-hidden relative transition-all w-full">
        {pets.data.records.slice(0, 12).map((item) => {
          return (
            <div key={item.petId} className="mb-4 z-0 w-full">
              <PetCard
                animalInfo={item as unknown as PetCardProps}
                onClick={onPetClick}
              ></PetCard>
            </div>
          );
        })}
      </div>

      <PetDetailModal ref={detailModal} animalInfo={curPet}></PetDetailModal>
    </div>
  );
}

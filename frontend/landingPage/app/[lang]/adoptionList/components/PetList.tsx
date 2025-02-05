"use client";
import { useEffect } from "react";
import Image from "next/image"
import { TestimonialsData } from "@/config/testimonials";
import Link from "next/link";
import { TwitterX } from "@/components/social-icons/icons";
import Filter from './Filter'
import PetCard, { PetCardProps } from "./PetCard";
import pets from '@/raw-datas/1.json';

async function fetchPets() {
    const response = await fetch(`/api/pets`);
    if (!response.ok) {
        throw new Error("Failed to fetch pets");
    }
    const result = await response.json();
    return result.data;
}
export function PetList() {

    useEffect(() => {
        fetchPets().then((pets) => {
            // setTask(t);
            console.log('fetch pets = ', pets)
        })
            .finally(() => {
            });;
    })

    const onSearch = (searchTerm: string) => {
        console.log(searchTerm)
    }

    return <div className="flex flex-col justify-center items-center w-5/6">
        <div className="flex justify-start items-center mb-4 w-full">
            <Filter searchCallback={onSearch}></Filter>
        </div>
        <div className="columns-1 sm:columns-2 lg:columns-3 xl:columns-4 gap-4 overflow-hidden relative transition-all w-full">
            {pets.data.records.slice(0, 12).map(item => {
                return (
                    <div key={item.petId} className="mb-4 z-0 w-full">
                        <PetCard animalInfo={item as unknown as PetCardProps}></PetCard>
                    </div>
                )
            })}
        </div>
    </div>
}
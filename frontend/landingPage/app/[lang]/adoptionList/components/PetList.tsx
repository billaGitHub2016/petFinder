"use client";
import { useState, useEffect, useRef } from "react";
import { useInfiniteQuery } from "@tanstack/react-query"
import { useInView } from "react-intersection-observer"
import qs from 'qs'
import Filter from "./Filter";
import PetCard, { PetCardProps } from "./PetCard";
import petsJson from "@/raw-datas/1.json";
import PetDetailModal from "./PetDetailModal";
import AdoptApplyModal from "./AdoptApplyModal";

async function fetchPets({ pageParam = 1 }) {
    const query = qs.stringify({
        pagination: {
            page: pageParam,
            pageSize: 8,
        },
    }, {
        encodeValuesOnly: true, // prettify URL
    });
    const response = await fetch(`/api/pets?${query}`);
    if (!response.ok) {
        throw new Error("Failed to fetch pets");
    }
    const result = await response.json();
    return result.data;
}
export function PetList() {

    const detailModal = useRef<{ setOpen: Function }>(null);
    const adoptApplyModal = useRef<{ setOpen: Function }>(null);
    const { ref, inView } = useInView()
    const { data, error, fetchNextPage, hasNextPage, isFetchingNextPage, status } = useInfiniteQuery({
        queryKey: ["pets"],
        queryFn: fetchPets,
        getNextPageParam: (lastPage) => {
            console.log('lastPage = ', lastPage)
            return (lastPage.meta.pagination.page >= lastPage.meta.pagination.pageCount) ? null : lastPage.meta.pagination.page + 1;
        },
        initialPageParam: 1
    })
    // console.log("data = ", data)
    // const pets = data?.pages.map((page) => page.data).flat() || [];
    // console.log("pets = ", pets)
    const pets = petsJson.data.records;

    // useEffect(() => {
    //     if (inView && hasNextPage) {
    //         fetchNextPage()
    //         console.log("fetch next page@@@@@@@@@@@@@")
    //     }
    // }, [inView, fetchNextPage, hasNextPage])

    const onSearch = (searchTerm: string) => {
        console.log(searchTerm);
    };

    const [curPet, setCurPet] = useState(null);
    const onPetClick = (pet: PetCardProps) => {
        console.log("click pet = ", pet);
        detailModal.current?.setOpen(true);
        setCurPet(pet);
    };
    const onAdopt = () => {
        // console.log("onAdopt");
        adoptApplyModal.current?.setOpen(true);
    }

    return (

        <div className="flex flex-col justify-center items-center w-5/6">
            <div className="flex justify-start items-center mb-4 w-full">
                <Filter searchCallback={onSearch}></Filter>
            </div>
            <div className="columns-1 sm:columns-2 lg:columns-3 xl:columns-4 gap-4 overflow-hidden relative transition-all w-full">
                {pets.map((item: any) => {
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
            <div ref={ref} className="h-10 flex items-center justify-center">
                {isFetchingNextPage ? "Loading more..." : hasNextPage ? "Load More" : "No more pets to load"}
            </div>
            <PetDetailModal ref={detailModal} animalInfo={curPet} onAdopt={onAdopt}></PetDetailModal>
            <AdoptApplyModal ref={adoptApplyModal}></AdoptApplyModal>
        </div>
    );
}

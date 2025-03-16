"use client";

import { useEffect, useState } from "react";
import { Cat, Dog } from "lucide-react";

import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { useParams } from "next/navigation";
import { getDictionary } from "@/lib/i18n";

export default function Filter({
  searchCallback,
}: {
  searchCallback: (searchType: string) => void;
}) {
  const [searchType, setSearchType] = useState("");
  const [dict, setDict] = useState<any>();
  const params = useParams();
  const lang = params.lang as string;

  useEffect(() => {
    getDictionary(lang).then(setDict);
  }, [lang]);

  return (
    <div>
      <ToggleGroup
        type="single"
        defaultValue={""}
        value={searchType}
        onValueChange={(value) => {
          setSearchType(value);
          searchCallback(value);
        }}
      >
        <ToggleGroupItem value="dog" aria-label="Toggle dog">
          <Dog className="h-4 w-4" />
          {dict?.AdoptionCenter.dog}
        </ToggleGroupItem>
        <ToggleGroupItem value="cat" aria-label="Toggle cat">
          <Cat className="h-4 w-4" />
          {dict?.AdoptionCenter.cat}
        </ToggleGroupItem>
      </ToggleGroup>
    </div>
  );
}

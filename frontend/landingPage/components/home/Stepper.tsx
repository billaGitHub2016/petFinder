import { ALL_FEATURES } from "@/config/feature";
import React from "react";
import { RoughNotation } from "react-rough-notation";
import { AuditOutlined, SmileOutlined, SolutionOutlined, UserOutlined } from '@ant-design/icons';
import { Steps } from 'antd';
import { Button } from "@/components/ui/button";
import Link from "next/link";

const Feature = ({
  id,
  locale,
  lang,
}: {
  id: string;
  locale: any;
  lang: string;
}) => {
  return (
    <section
      id={id}
      className="flex flex-col justify-center lg:max-w-7xl md:max-w-5xl w-[95%] mx-auto md:gap-14 pt-16 to-orange-300"
    >
      <h2 className="text-center text-white">
        <RoughNotation type="highlight" show={true} color="#F97316">
          {locale.title || "Adoption Steps"}
        </RoughNotation>
      </h2>
      <Link
        href={`/${lang === "en" ? "" : lang}/adoptionList`}
        rel="noopener noreferrer nofollow"
        className="flex justify-center"
      >
        <Button
          variant="default"
          className="flex items-center gap-2 text-white"
          aria-label="Get Boilerplate"
        >
          {locale.goto}
        </Button>
      </Link>
      <Steps
        items={[
          {
            title: locale.step1Title,
            status: 'finish',
            icon: <UserOutlined />,
            description: locale.step1Description
          },
          {
            title: locale.step2Title,
            status: 'finish',
            icon: <SolutionOutlined />,
            description: locale.step2Description
          },
          {
            title: locale.step3Title,
            status: 'finish',
            icon: <AuditOutlined />,
            description: locale.step3Description
          },
          {
            title: locale.step4Title,
            status: 'finish',
            icon: <SmileOutlined />,
            description: locale.step4Description
          },
        ]}
      />
    </section>
  );
};

export default Feature;

"use client";
import HeaderLinks from "@/components/header/HeaderLinks";
import { LangSwitcher } from "@/components/header/LangSwitcher";
import { siteConfig } from "@/config/site";
import { MenuIcon } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useParams, usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { CgClose } from "react-icons/cg";
import { ThemedButton } from "../ThemedButton";
import LoginButton from "./LoginButton";
import { ConnectButton } from "@mysten/dapp-kit";
import { defaultLocale, getDictionary } from "@/lib/i18n";

const links = [
  { label: "home", href: "" },
  { label: "adoptionCenter", href: "adoptionList" },
  // { label: "Testimonials", href: "#Testimonials" },
  { label: "my", href: "/myApply" },
];

const Header = (user: any) => {
  // console.log('user header = ', user);
  const params = useParams();
  const lang = params.lang as string;
  // console.log("lang = ", lang);
  const pathName = usePathname();
  // console.log("pathName = ", pathName);
  const [dict, setDict] = useState<any>();

  useEffect(() => {
    getDictionary(lang).then(setDict);
  }, [lang]);

  const [isMenuOpen, setIsMenuOpen] = useState(false);
  return (
    <header className="py-10 mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 w-full">
      <nav className="relative z-50 flex justify-between items-center">
        {/* Left section */}
        <div className="flex items-center md:gap-x-12 flex-1">
          <Link
            href="/"
            aria-label="Landing Page Boilerplate"
            title="Landing Page Boilerplate"
            className="flex items-center space-x-1 font-bold"
          >
            <Image
              alt="Logo"
              src="/pet-finder-logo-3.png"
              className="rounded-sm"
              width={48}
              height={48}
            />
            <span className="text-gray-950 dark:text-gray-300 hidden md:block">
              {siteConfig.name}
            </span>
          </Link>
        </div>

        {/* Center section - Navigation */}
        <ul className="hidden md:flex items-center justify-center gap-6 flex-1">
          {links.map((link) => (
            <li key={link.label} className="relative">
              <Link
                href={`/${lang === "en" || !lang ? "en/" : lang + "/"}${
                  link.href
                }`}
                aria-label={dict?.Links[link.label]}
                title={link.label}
                className="tracking-wide transition-colors duration-200 font-normal"
              >
                {dict?.Links[link.label]}
              </Link>
              {((link.href && pathName.indexOf(link.href) > -1) || (link.href === '' && (pathName === "/en" || pathName === "/zh" || pathName === "/"))) && (
                <span className="w-3/4 h-1 bg-orange-400 absolute -bottom-1 left-1/2 -translate-x-1/2"></span>
              )}
            </li>
          ))}
        </ul>

        {/* Right section */}
        <div className="hidden md:flex items-center justify-end gap-x-6 flex-1">
          {/* <HeaderLinks /> */}
          {/* <ThemedButton /> */}
          <LangSwitcher />
          <ConnectButton></ConnectButton>
          <LoginButton userData={user} lang={lang}></LoginButton>
        </div>

        {/* Mobile menu button */}
        <div className="md:hidden">
          <button
            aria-label="Open Menu"
            title="Open Menu"
            className="p-2 -mr-1 transition duration-200 rounded focus:outline-none focus:shadow-outline hover:bg-deep-purple-50 focus:bg-deep-purple-50"
            onClick={() => setIsMenuOpen(true)}
          >
            <MenuIcon />
          </button>
          {isMenuOpen && (
            <div className="absolute top-0 left-0 w-full z-50">
              <div className="p-5 bg-background border rounded shadow-sm">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <Link
                      href="/zh"
                      aria-label="Landing Page Boilerplate"
                      title="Landing Page Boilerplate"
                      className="inline-flex items-center"
                    >
                      <Image
                        alt={siteConfig.name}
                        src="/logo.svg"
                        className="w-8 h-8"
                        width={32}
                        height={32}
                      />
                      <span className="ml-2 text-xl font-bold tracking-wide text-gray-950 dark:text-gray-300">
                        {siteConfig.name}
                      </span>
                    </Link>
                  </div>
                  <div>
                    <button
                      aria-label="Close Menu"
                      title="Close Menu"
                      className="tracking-wide transition-colors duration-200 font-normal"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      <CgClose />
                    </button>
                  </div>
                </div>
                <nav>
                  <ul className="space-y-4">
                    {links.map((link) => (
                      <li key={link.label}>
                        <Link
                          href={link.href}
                          aria-label={link.label}
                          title={link.label}
                          className="font-medium tracking-wide transition-colors duration-200 hover:text-deep-purple-accent-400"
                          onClick={() => setIsMenuOpen(false)}
                        >
                          {link.label}
                        </Link>
                      </li>
                    ))}
                  </ul>
                </nav>
                <div className="pt-4">
                  <div className="flex items-center gap-x-5 justify-between">
                    <HeaderLinks />
                    <div className="flex items-center justify-end gap-x-5">
                      {/* <ThemedButton /> */}
                      <LangSwitcher />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </nav>
    </header>
  );
};

export default Header;

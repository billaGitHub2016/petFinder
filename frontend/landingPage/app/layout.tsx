import BaiDuAnalytics from "@/app/BaiDuAnalytics";
import GoogleAnalytics from "@/app/GoogleAnalytics";
import { TailwindIndicator } from "@/components/TailwindIndicator";
import { ThemeProvider } from "@/components/ThemeProvider";
import Footer from "@/components/footer/Footer";
import Header from "@/components/header/Header";
import { siteConfig } from "@/config/site";
import { defaultLocale } from "@/lib/i18n";
import { cn } from "@/lib/utils";
import "@/styles/globals.css";
import "@/styles/loading.css";
import { Analytics } from "@vercel/analytics/react";
import { Viewport } from "next";
import { Inter as FontSans } from "next/font/google";
// import { createServerComponentClient } from "@supabase/auth-helpers-nextjs";
import { createClient } from "@/utils/supabase/server";
import { AntdRegistry } from '@ant-design/nextjs-registry';
import { ConfigProvider } from 'antd';
// import { cookies } from "next/headers";
// import { Database } from "@/types/supabase";


export const dynamic = "force-dynamic";

export const fontSans = FontSans({
  subsets: ["latin"],
  variable: "--font-sans",
});

export const metadata = {
  title: siteConfig.name,
  description: siteConfig.description,
  keywords: siteConfig.keywords,
  authors: siteConfig.authors,
  creator: siteConfig.creator,
  icons: siteConfig.icons,
  metadataBase: siteConfig.metadataBase,
  openGraph: siteConfig.openGraph,
  twitter: siteConfig.twitter,
};
export const viewport: Viewport = {
  themeColor: siteConfig.themeColors,
};
export default async function RootLayout({
  children,
  params: { lang },
}: {
  children: React.ReactNode;
  params: { lang: string | undefined };
}) {

  // 创建一个Supabase客户端
  //  const supabase = createServerComponentClient<Database>({ cookies });
  const supabase = await createClient();

  // 获取当前用户信息
  const {
    data: { user },
  } = await supabase.auth.getUser();
  //  console.log('!!!!!!!!!user = ', user);

  return (
    <html lang={lang || defaultLocale} suppressHydrationWarning>
      <head />
      <body
        className={cn(
          "min-h-screen bg-background font-sans antialiased",
          fontSans.variable
        )}
      >
        <AntdRegistry>
          <ConfigProvider
            theme={{
              token: {
                // Seed Token，影响范围大
                colorPrimary: '#F97316'
              },
            }}
          >
            <ThemeProvider
              attribute="class"
              defaultTheme={siteConfig.nextThemeColor}
              enableSystem
            >
              <Header user={user} />
              <main className="flex flex-col items-center py-6">{children}</main>
              <Footer />
              <Analytics />
              <TailwindIndicator />
            </ThemeProvider>
            {process.env.NODE_ENV === "development" ? (
              <></>
            ) : (
              <>
                <GoogleAnalytics />
                <BaiDuAnalytics />
              </>
            )}
          </ConfigProvider>
        </AntdRegistry>
      </body>
    </html>
  );
}

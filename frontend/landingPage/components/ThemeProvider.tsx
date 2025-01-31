"use client";

import { ThemeProvider as NextThemesProvider } from "next-themes";
import { ThemeProviderProps } from "next-themes/dist/types";
import { ThemeProvider as MaterialThemeProvider } from "@material-tailwind/react";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return (
    <NextThemesProvider {...props}>
      <MaterialThemeProvider {...props}>{children}</MaterialThemeProvider>
    </NextThemesProvider>
  );
}


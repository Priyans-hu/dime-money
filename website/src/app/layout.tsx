import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Dime Money — Personal Finance Tracker",
  description:
    "A beautiful, privacy-first personal finance tracker. Track expenses, manage budgets, and gain insights — all stored locally on your device.",
  openGraph: {
    title: "Dime Money — Personal Finance Tracker",
    description:
      "A beautiful, privacy-first personal finance tracker built with Flutter.",
    type: "website",
    url: "https://priyans-hu.github.io/dime-money/",
  },
  icons: {
    icon: "/dime-money/app_icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${geistSans.variable} ${geistMono.variable} font-sans antialiased`}
      >
        {children}
      </body>
    </html>
  );
}

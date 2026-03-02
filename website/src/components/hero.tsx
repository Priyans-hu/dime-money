"use client";

import { Button } from "@/components/ui/button";
import { FadeIn } from "@/components/fade-in";
import { PhoneMockup } from "@/components/phone-mockup";
import { Github, Download } from "lucide-react";
import Image from "next/image";

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center overflow-hidden">
      {/* Purple radial gradient background */}
      <div
        className="absolute inset-0 opacity-30"
        style={{
          background:
            "radial-gradient(ellipse 80% 60% at 50% 40%, #6750A4 0%, transparent 70%)",
        }}
      />

      <div className="relative z-10 mx-auto max-w-6xl px-6 py-24 w-full">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Left: Text */}
          <div className="space-y-6">
            <FadeIn>
              <div className="flex items-center gap-3 mb-4">
                <div className="w-14 h-14 rounded-2xl bg-brand flex items-center justify-center">
                  <Image
                    src="/dime-money/app_icon_foreground.png"
                    alt="Dime Money icon"
                    width={40}
                    height={40}
                  />
                </div>
                <h1 className="text-4xl md:text-5xl font-bold text-white">
                  Dime Money
                </h1>
              </div>
            </FadeIn>

            <FadeIn delay={0.1}>
              <p className="text-lg md:text-xl text-[#938F99] max-w-md">
                A beautiful, privacy-first personal finance tracker. Your data
                stays on your device — always.
              </p>
            </FadeIn>

            <FadeIn delay={0.2}>
              <div className="flex flex-wrap gap-3 pt-2">
                <Button asChild size="lg" className="bg-brand hover:bg-brand/90 text-white">
                  <a href="https://github.com/Priyans-hu/dime_money/releases" target="_blank" rel="noopener noreferrer">
                    <Download className="mr-2 h-4 w-4" />
                    Download
                  </a>
                </Button>
                <Button asChild variant="outline" size="lg" className="border-white/10 text-white hover:bg-white/5">
                  <a href="https://github.com/Priyans-hu/dime_money" target="_blank" rel="noopener noreferrer">
                    <Github className="mr-2 h-4 w-4" />
                    View Source
                  </a>
                </Button>
              </div>
            </FadeIn>
          </div>

          {/* Right: Phone mockup */}
          <FadeIn delay={0.3} className="hidden lg:flex justify-center">
            <PhoneMockup />
          </FadeIn>
        </div>
      </div>
    </section>
  );
}

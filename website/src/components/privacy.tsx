"use client";

import { Card, CardContent } from "@/components/ui/card";
import { FadeIn } from "@/components/fade-in";
import { HardDrive, UserX, Code2, Smartphone } from "lucide-react";

const points = [
  {
    icon: HardDrive,
    title: "100% Local Storage",
    description:
      "All your financial data is stored on your device. Nothing leaves your phone — no servers, no cloud sync, no tracking.",
  },
  {
    icon: UserX,
    title: "No Account Required",
    description:
      "No sign-ups, no emails, no passwords. Just install and start tracking. Your finances, your business.",
  },
  {
    icon: Code2,
    title: "Open Source",
    description:
      "The entire codebase is public on GitHub. Audit it, fork it, contribute to it. Full transparency, always.",
  },
  {
    icon: Smartphone,
    title: "Cross-Platform",
    description:
      "Built with Flutter for a smooth, native experience on Android. iOS support is on the roadmap.",
  },
];

export function Privacy() {
  return (
    <section id="privacy" className="py-24 px-6">
      <div className="mx-auto max-w-6xl">
        <FadeIn>
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Privacy by design
            </h2>
            <p className="text-[#938F99] max-w-lg mx-auto">
              Built from the ground up to respect your data and your trust.
            </p>
          </div>
        </FadeIn>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {points.map((point, i) => (
            <FadeIn key={point.title} delay={i * 0.1}>
              <Card className="bg-surface border-white/5 hover:border-brand/30 transition-colors h-full">
                <CardContent className="pt-6">
                  <div className="flex items-center gap-4">
                    <div className="shrink-0 w-12 h-12 rounded-xl bg-brand/20 flex items-center justify-center">
                      <point.icon className="h-6 w-6 text-brand-light" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-white text-lg mb-1">
                        {point.title}
                      </h3>
                      <p className="text-sm text-[#938F99] leading-relaxed">
                        {point.description}
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}

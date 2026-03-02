"use client";

import { Card, CardContent } from "@/components/ui/card";
import { FadeIn } from "@/components/fade-in";
import {
  PlusCircle,
  Tags,
  Wallet,
  Target,
  BarChart3,
  RefreshCw,
  Fingerprint,
  ArrowUpDown,
} from "lucide-react";

const features = [
  {
    icon: PlusCircle,
    title: "Quick Add",
    description: "Add transactions in seconds with a streamlined input flow.",
  },
  {
    icon: Tags,
    title: "Categories",
    description: "Organize spending with custom categories and color-coded tags.",
  },
  {
    icon: Wallet,
    title: "Multiple Accounts",
    description: "Track cash, bank accounts, and cards all in one place.",
  },
  {
    icon: Target,
    title: "Budgets",
    description: "Set monthly budgets per category and track your progress.",
  },
  {
    icon: BarChart3,
    title: "Dashboard",
    description: "Visual charts and breakdowns of your spending patterns.",
  },
  {
    icon: RefreshCw,
    title: "Recurring",
    description: "Automate tracking for subscriptions and recurring expenses.",
  },
  {
    icon: Fingerprint,
    title: "Biometric Lock",
    description: "Secure your financial data with fingerprint or face unlock.",
  },
  {
    icon: ArrowUpDown,
    title: "Import / Export",
    description: "Backup and restore your data with CSV import and export.",
  },
];

export function Features() {
  return (
    <section id="features" className="py-24 px-6">
      <div className="mx-auto max-w-6xl">
        <FadeIn>
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Everything you need
            </h2>
            <p className="text-[#938F99] max-w-lg mx-auto">
              Packed with features to help you take control of your finances.
            </p>
          </div>
        </FadeIn>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {features.map((feature, i) => (
            <FadeIn key={feature.title} delay={i * 0.05}>
              <Card className="bg-surface border-white/5 hover:border-brand/30 transition-colors h-full">
                <CardContent className="pt-6">
                  <feature.icon className="h-8 w-8 text-brand-light mb-3" />
                  <h3 className="font-semibold text-white mb-1">
                    {feature.title}
                  </h3>
                  <p className="text-sm text-[#938F99]">
                    {feature.description}
                  </p>
                </CardContent>
              </Card>
            </FadeIn>
          ))}
        </div>
      </div>
    </section>
  );
}

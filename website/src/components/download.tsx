"use client";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { FadeIn } from "@/components/fade-in";
import { Download as DownloadIcon } from "lucide-react";

export function DownloadSection() {
  return (
    <section id="download" className="py-24 px-6">
      <div className="mx-auto max-w-3xl">
        <FadeIn>
          <div
            className="rounded-2xl p-10 md:p-14 text-center"
            style={{
              background:
                "linear-gradient(135deg, #6750A4 0%, #381E72 100%)",
            }}
          >
            <Badge variant="secondary" className="mb-4 bg-white/20 text-white border-0">
              v0.6.0
            </Badge>
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-3">
              Ready to take control?
            </h2>
            <p className="text-white/80 mb-8 max-w-md mx-auto">
              Download Dime Money from GitHub Releases. Free, open-source,
              and always will be.
            </p>
            <Button
              asChild
              size="lg"
              className="bg-white text-[#381E72] hover:bg-white/90 font-semibold"
            >
              <a
                href="https://github.com/Priyans-hu/dime_money/releases"
                target="_blank"
                rel="noopener noreferrer"
              >
                <DownloadIcon className="mr-2 h-4 w-4" />
                Download from GitHub
              </a>
            </Button>
          </div>
        </FadeIn>
      </div>
    </section>
  );
}

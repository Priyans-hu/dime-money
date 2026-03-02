"use client";

import { Separator } from "@/components/ui/separator";
import { Github, Linkedin, Instagram, Mail } from "lucide-react";

const socials = [
  { icon: Github, href: "https://github.com/Priyans-hu", label: "GitHub" },
  { icon: Linkedin, href: "https://linkedin.com/in/priyans-hu", label: "LinkedIn" },
  { icon: Instagram, href: "https://instagram.com/shotbypriyanshu", label: "Instagram" },
  { icon: Mail, href: "mailto:pg.tldr@gmail.com", label: "Email" },
];

export function Footer() {
  return (
    <footer className="py-12 px-6">
      <div className="mx-auto max-w-6xl">
        <Separator className="mb-8 bg-white/10" />
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          <p className="text-sm text-[#938F99]">
            Made with care by{" "}
            <a
              href="https://github.com/Priyans-hu"
              target="_blank"
              rel="noopener noreferrer"
              className="text-brand-light hover:underline"
            >
              Priyanshu
            </a>
          </p>
          <div className="flex items-center gap-4">
            {socials.map((social) => (
              <a
                key={social.label}
                href={social.href}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={social.label}
                className="text-[#938F99] hover:text-brand-light transition-colors"
              >
                <social.icon className="h-5 w-5" />
              </a>
            ))}
          </div>
          <p className="text-sm text-[#938F99]">
            &copy; {new Date().getFullYear()} Dime Money
          </p>
        </div>
      </div>
    </footer>
  );
}

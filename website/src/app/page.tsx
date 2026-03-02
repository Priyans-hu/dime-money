import { Hero } from "@/components/hero";
import { Features } from "@/components/features";
import { Privacy } from "@/components/privacy";
import { DownloadSection } from "@/components/download";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main className="min-h-screen">
      <Hero />
      <Features />
      <Privacy />
      <DownloadSection />
      <Footer />
    </main>
  );
}

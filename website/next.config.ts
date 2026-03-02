import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  basePath: "/dime-money",
  images: {
    unoptimized: true,
  },
};

export default nextConfig;

import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Cursor-Browser / Tools nutzen oft 127.0.0.1 statt localhost —
  // ohne Eintrag blockiert Next Dev die JS-Chunks (keine Hydration).
  allowedDevOrigins: ["127.0.0.1", "localhost"],
  async redirects() {
    return [
      { source: "/touren", destination: "/discover", permanent: false },
      { source: "/touren/:path*", destination: "/discover", permanent: false },
      { source: "/tours", destination: "/discover", permanent: false },
      // Shop Parts aliases (Test Agent P0)
      { source: "/teile", destination: "/shop/parts", permanent: false },
      { source: "/teile/:path*", destination: "/shop/parts", permanent: false },
      { source: "/parts", destination: "/shop/parts", permanent: false },
      { source: "/parts/:path*", destination: "/shop/parts", permanent: false },
    ];
  },
};

export default nextConfig;

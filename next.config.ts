import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Cursor-Browser / Tools nutzen oft 127.0.0.1 statt localhost —
  // ohne Eintrag blockiert Next Dev die JS-Chunks (keine Hydration).
  allowedDevOrigins: ["127.0.0.1", "localhost"],
};

export default nextConfig;

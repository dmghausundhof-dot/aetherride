import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Cursor-Browser / Tools nutzen oft 127.0.0.1 statt localhost —
  // ohne Eintrag blockiert Next Dev die JS-Chunks (keine Hydration).
  allowedDevOrigins: ["127.0.0.1", "localhost"],
  // Pack-Dateien liegen außerhalb des App-Trees; dynamisches readFile
  // darf sie nicht in den Serverless-Trace ziehen (Copy-auf-sich-selbst).
  outputFileTracingExcludes: {
    "/*": [
      "./data/routing/dist/**",
      "./mobile/**",
      "./.test-screenshots/**",
      "./public/offline/**",
    ],
    "/api/offline/*": ["./data/routing/dist/**", "./public/offline/**"],
  },
  async redirects() {
    return [
      { source: "/touren", destination: "/discover", permanent: false },
      { source: "/touren/:path*", destination: "/discover", permanent: false },
      { source: "/tours", destination: "/discover", permanent: false },
      // Exact /shop/parts · /teile · /parts: App-Router (Query + door=parts).
      { source: "/teile/:path*", destination: "/shop", permanent: false },
      { source: "/parts/:path*", destination: "/shop", permanent: false },
      { source: "/shop/parts/:path*", destination: "/shop", permanent: false },
    ];
  },
};

export default nextConfig;

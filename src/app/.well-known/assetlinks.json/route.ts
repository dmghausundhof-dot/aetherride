import { NextResponse } from "next/server";
import {
  ANDROID_PACKAGE,
  androidSha256Fingerprints,
} from "@/lib/web/appLinks";

/**
 * Android App Links — Digital Asset Links.
 * Fingerprints: NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS=AA:BB:...
 */
export async function GET() {
  const fps = androidSha256Fingerprints();
  const body = [
    {
      relation: ["delegate_permission/common.handle_all_urls"],
      target: {
        namespace: "android_app",
        package_name: ANDROID_PACKAGE,
        sha256_cert_fingerprints:
          fps.length > 0
            ? fps
            : [
                // Placeholder — ohne echten Fingerprint validiert Google nicht
                "00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00",
              ],
      },
    },
  ];

  return new NextResponse(JSON.stringify(body), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=3600",
    },
  });
}

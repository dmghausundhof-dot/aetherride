import { NextResponse } from "next/server";
import { IOS_BUNDLE_ID, IOS_TEAM_ID } from "@/lib/web/appLinks";

/**
 * Apple Universal Links — ohne Dateiendung, application/json.
 * Team ID in Vercel: NEXT_PUBLIC_IOS_TEAM_ID
 */
export async function GET() {
  const appID = IOS_TEAM_ID
    ? `${IOS_TEAM_ID}.${IOS_BUNDLE_ID}`
    : IOS_BUNDLE_ID;

  const body = {
    applinks: {
      apps: [],
      details: [
        {
          appID,
          paths: [
            "/open/*",
            "/ride",
            "/ride/*",
            "/tours/*",
            "/discover",
            "/download",
          ],
        },
      ],
    },
    webcredentials: {
      apps: IOS_TEAM_ID ? [`${IOS_TEAM_ID}.${IOS_BUNDLE_ID}`] : [],
    },
  };

  return new NextResponse(JSON.stringify(body), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=3600",
    },
  });
}

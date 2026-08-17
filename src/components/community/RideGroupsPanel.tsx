"use client";

import { useEffect, useState } from "react";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import Link from "next/link";
import { canAttachCourse } from "@/lib/community/rideGroup";
import {
  fetchPublicRideGroups,
  isCloudFail,
  rideGroupHasSession,
} from "@/lib/community/rideGroupCloud";
import type { VisibilityScope } from "@/lib/tours/routeVisibility";
import {
  encodeGroupInvite,
  groupInviteHttps,
  parsePastedGroupJoin,
  publicProfileShareUrl,
} from "@/lib/community/rideGroupInvite";
import {
  isRideGroupSelf,
  listedRideGroups,
  useRideGroupStore,
  LOCAL_ONLY_NOTE,
} from "@/store/useRideGroupStore";
import { useCommunityStore } from "@/store/useCommunityStore";
import type { RideGroup } from "@/lib/community/types";
import type { SavedRoute } from "@/types/route";
import {
  formatPlatzGroupWhen,
  platzCopy,
  platzNote,
  type PlatzCopy,
} from "@/lib/i18n/platzCopy";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { webChrome } from "@/lib/i18n/webChrome";

function inviteUrl(group: RideGroup): string {
  return groupInviteHttps(group.id || group.joinCode, encodeGroupInvite(group));
}

function shareText(group: RideGroup, g: PlatzCopy, lang: ChromeLang): string {
  const url = inviteUrl(group);
  const profile = useCommunityStore.getState().publicProfile;
  const profileUrl =
    profile.enabled && profile.handle
      ? publicProfileShareUrl(profile.handle)
      : undefined;
  const when = formatPlatzGroupWhen(
    group.startWindowStart,
    group.startWindowEnd,
    lang,
  );
  const lines = [g.shareTitle(group.title), url];
  if (when) lines.push(when);
  if (group.meetingPoint?.trim()) lines.push(g.shareMeet(group.meetingPoint.trim()));
  if (profileUrl) lines.push("", g.shareProfile(profileUrl));
  lines.push(
    "",
    group.visibility === "public" ? g.shareVisPublic : g.shareVisPrivate,
  );
  return lines.join("\n");
}

async function shareInvite(
  group: RideGroup,
  setMsg: (m: string) => void,
  g: PlatzCopy,
  lang: ChromeLang,
) {
  const url = inviteUrl(group);
  const text = shareText(group, g, lang);
  const nav = navigator as Navigator & {
    share?: (data: ShareData) => Promise<void>;
  };
  if (typeof nav.share === "function") {
    try {
      await nav.share({ title: g.shareTitle(group.title), text, url });
      return;
    } catch {
      /* Abbruch oder Fallback */
    }
  }
  await copyInvite(group, setMsg, g);
}

async function copyInvite(
  group: RideGroup,
  setMsg: (m: string) => void,
  g: PlatzCopy,
) {
  const url = inviteUrl(group);
  try {
    await navigator.clipboard.writeText(url);
    setMsg(g.copiedInvite);
  } catch {
    setMsg(url);
  }
}

export function RideGroupsPanel({
  savedRoutes,
  visibility = "all_mine",
}: {
  savedRoutes: SavedRoute[];
  visibility?: VisibilityScope;
}) {
  const hof = useHofCopy();
  const lang = useChromeLang();
  const g = platzCopy(lang);
  const chrome = webChrome(lang);
  const groups = useRideGroupStore((s) => s.groups);
  const members = useRideGroupStore((s) => s.members);
  const localUserId = useRideGroupStore((s) => s.localUserId);
  const cloudUserId = useRideGroupStore((s) => s.cloudUserId);
  const lastNote = useRideGroupStore((s) => s.lastNote);
  const joinFromInviteAsync = useRideGroupStore((s) => s.joinFromInviteAsync);
  const createGroupAsync = useRideGroupStore((s) => s.createGroupAsync);
  const setLiveOptIn = useRideGroupStore((s) => s.setLiveOptIn);
  const setVisibilityAsync = useRideGroupStore((s) => s.setVisibilityAsync);
  const leaveGroupAsync = useRideGroupStore((s) => s.leaveGroupAsync);
  const pullCloud = useRideGroupStore((s) => s.pullCloud);
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const selfIds = { localUserId, cloudUserId };
  const selfLabel = publicProfile.enabled
    ? publicProfile.displayName.trim() ||
      (publicProfile.handle ? `@${publicProfile.handle}` : g.you)
    : g.you;
  const [msg, setMsg] = useState<string | null>(null);
  const [picked, setPicked] = useState("");
  const [listing, setListing] = useState<"private" | "public">("private");
  const [startsLocal, setStartsLocal] = useState("");
  const [durationH, setDurationH] = useState(3);
  const [meeting, setMeeting] = useState("");
  const [joinPaste, setJoinPaste] = useState("");
  const [signedIn, setSignedIn] = useState(true);
  const [publicGroups, setPublicGroups] = useState<RideGroup[]>([]);
  const attachable = savedRoutes.filter((r) => canAttachCourse(r));
  const open = listedRideGroups(groups);
  const mineIds = new Set(open.map((group) => group.id));
  const listedPublic = publicGroups.filter((group) => !mineIds.has(group.id));
  const shownNote = lastNote ? platzNote(lastNote, lang) : "";

  useEffect(() => {
    void pullCloud();
    void rideGroupHasSession().then(setSignedIn);
  }, [pullCloud]);
  useEffect(() => {
    if (visibility !== "shared") {
      setPublicGroups([]);
      return;
    }
    void fetchPublicRideGroups().then((out) => {
      if (!isCloudFail(out)) setPublicGroups(out.groups);
    });
  }, [visibility]);

  return (
    <section className="mt-10">
      <h2 className="mb-1 text-sm font-semibold tracking-wide text-text-secondary">
        {hof.togetherOut}
      </h2>
      <p className="mb-3 text-xs text-text-secondary">{g.inviteHint}</p>
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <select
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          value={picked}
          onChange={(e) => setPicked(e.target.value)}
        >
          <option value="">{g.pickTour}</option>
          {attachable.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
        <select
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          value={listing}
          onChange={(e) =>
            setListing(e.target.value === "public" ? "public" : "private")
          }
        >
          <option value="private">{g.visPrivate}</option>
          <option value="public">{g.visPublic}</option>
        </select>
        <input
          type="datetime-local"
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          value={startsLocal}
          onChange={(e) => setStartsLocal(e.target.value)}
        />
        <select
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          value={durationH}
          onChange={(e) => setDurationH(Number(e.target.value))}
        >
          <option value={2}>2 h</option>
          <option value={3}>3 h</option>
          <option value={4}>4 h</option>
        </select>
        <input
          type="text"
          maxLength={80}
          placeholder={g.meetingPlaceholder}
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          value={meeting}
          onChange={(e) => setMeeting(e.target.value)}
        />
        <button
          type="button"
          className="rounded-xl bg-accent px-3 py-1.5 text-xs font-semibold text-on-accent"
          onClick={() => {
            if (!signedIn) {
              setMsg(g.needSignIn);
              return;
            }
            const route = attachable.find((r) => r.id === picked);
            if (!route) {
              setMsg(g.needSharedTour);
              return;
            }
            const startsAt = startsLocal
              ? new Date(startsLocal).toISOString()
              : new Date().toISOString();
            void createGroupAsync({
              route,
              displayLabel: selfLabel,
              visibility: listing,
              startsAt,
              durationHours: durationH,
              meetingPoint: meeting.trim() || undefined,
            }).then((out) => {
              const note = useRideGroupStore.getState().lastNote;
              setMsg(
                "error" in out
                  ? platzNote(out.error, lang)
                  : g.created(note ? platzNote(note, lang) : null),
              );
              if (!("error" in out)) void shareInvite(out, setMsg, g, lang);
            });
          }}
        >
          {g.createGroup}
        </button>
      </div>
      <div className="mb-3 flex flex-wrap items-end gap-2">
        <input
          type="text"
          data-testid="platz-join-field"
          value={joinPaste}
          onChange={(e) => setJoinPaste(e.target.value)}
          placeholder={g.joinField}
          className="min-w-[12rem] flex-1 rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
        />
        <button
          type="button"
          data-testid="platz-join-submit"
          className="rounded-xl border border-border px-3 py-1.5 text-xs font-semibold text-foreground"
          onClick={() => {
            const parsed = parsePastedGroupJoin(joinPaste);
            if (!joinPaste.trim()) {
              setMsg(g.joinEmpty);
              return;
            }
            if (!parsed) {
              setMsg(g.joinInvalid);
              return;
            }
            void joinFromInviteAsync(parsed.ref, parsed.token).then((out) => {
              const note = useRideGroupStore.getState().lastNote;
              setMsg(
                "error" in out
                  ? platzNote(out.error, lang)
                  : out.onServer
                    ? g.joined(out.title)
                    : g.joinNotOnServer(
                        platzNote(note ?? LOCAL_ONLY_NOTE, lang),
                      ),
              );
              setJoinPaste("");
              void pullCloud();
            });
          }}
        >
          {signedIn ? g.joinWithLink : g.joinLocalCta}
        </button>
      </div>
      <p className="mb-3 text-[11px] text-text-secondary">{g.joinHint}</p>
      {!signedIn ? (
        <p className="mb-3 text-[11px] text-warning">{g.joinUnsignedHint}</p>
      ) : null}
      {msg ? (
        <p className="mb-3 text-xs text-text-secondary">{msg}</p>
      ) : shownNote ? (
        <p className="mb-3 text-xs text-text-secondary">{shownNote}</p>
      ) : null}
      {lastNote === LOCAL_ONLY_NOTE ? (
        <p className="mb-3 text-xs text-text-secondary">
          <Link href="/profile" className="font-semibold text-accent">
            {chrome.signIn}
          </Link>
          {g.localOnlyFoot}
        </p>
      ) : null}
      {open.length === 0 && listedPublic.length === 0 ? (
        <p className="text-sm text-text-secondary">{g.emptyAll}</p>
      ) : (
        <ul className="space-y-2">
          {open.map((group) => {
            const roster = members.filter((m) => m.groupId === group.id);
            const me = roster.find((m) => isRideGroupSelf(selfIds, m.userId));
            const host = isRideGroupSelf(selfIds, group.hostUserId);
            return (
              <li
                key={group.id}
                className="rounded-xl border border-border px-3 py-2.5"
              >
                <div className="flex items-baseline justify-between gap-2">
                  <p className="truncate text-sm font-semibold">{group.title}</p>
                  <p className="shrink-0 text-[11px] font-semibold text-text-secondary">
                    {host ? g.host : g.guest}
                  </p>
                </div>
                <p className="text-xs text-text-secondary">
                  {group.visibility === "public" ? g.visPublic : g.visPrivate} ·{" "}
                  {g.along(roster.length)} ·{" "}
                  {formatPlatzGroupWhen(
                    group.startWindowStart,
                    group.startWindowEnd,
                    lang,
                  )}
                  {group.meetingPoint ? ` · ${group.meetingPoint}` : ""} ·{" "}
                  {group.onServer ? g.onServer : g.onDevice}
                </p>
                {roster.length > 0 ? (
                  <p className="mt-1 truncate text-xs text-text-secondary">
                    {roster
                      .map((m) => {
                        const name = m.displayLabel.trim();
                        const role =
                          m.userId === group.hostUserId ? g.host : g.guest;
                        const self = isRideGroupSelf(selfIds, m.userId)
                          ? g.selfSuffix
                          : "";
                        return name ? `${name} · ${role}${self}` : `${role}${self}`;
                      })
                      .join("  ·  ")}
                  </p>
                ) : null}
                <div className="mt-1.5 flex flex-wrap items-center gap-2">
                  {host ? (
                    <button
                      type="button"
                      className="rounded-xl bg-accent px-3 py-1.5 text-xs font-semibold text-on-accent"
                      onClick={() => void shareInvite(group, setMsg, g, lang)}
                    >
                      {g.invite}
                    </button>
                  ) : null}
                  <button
                    type="button"
                    className="text-xs font-medium text-text-secondary"
                    onClick={() => void leaveGroupAsync(group.id)}
                  >
                    {host ? g.dissolve : g.leave}
                  </button>
                  {host || group.onServer ? (
                    <button
                      type="button"
                      className="text-xs font-medium text-text-secondary"
                      onClick={() => void copyInvite(group, setMsg, g)}
                    >
                      {g.copyLink}
                    </button>
                  ) : null}
                  {host ? (
                    <button
                      type="button"
                      className="text-xs font-medium text-text-secondary"
                      onClick={() =>
                        void setVisibilityAsync(
                          group.id,
                          group.visibility === "public" ? "private" : "public",
                        )
                      }
                    >
                      {group.visibility === "public"
                        ? g.makePrivate
                        : g.makePublic}
                    </button>
                  ) : null}
                </div>
                {group.onServer ? (
                  <button
                    type="button"
                    className="mt-1 text-[11px] text-text-secondary"
                    onClick={() => {
                      const next = !me?.liveOptIn;
                      setLiveOptIn(group.id, next);
                      if (next) setMsg(g.pinsHint);
                    }}
                  >
                    {me?.liveOptIn ? g.pinsOff : g.pinsHud}
                  </button>
                ) : null}
              </li>
            );
          })}
          {listedPublic.map((group) => (
            <li
              key={`pub-${group.id}`}
              className="flex items-center justify-between gap-3 rounded-xl border border-border px-3 py-2.5"
            >
              <div className="min-w-0">
                <p className="truncate text-sm font-semibold">{group.title}</p>
                <p className="text-xs text-text-secondary">{g.visPublic}</p>
              </div>
              <button
                type="button"
                className="rounded-xl bg-accent px-3 py-1.5 text-xs font-semibold text-on-accent"
                onClick={() => {
                  void joinFromInviteAsync(group.id).then((out) => {
                    const note = useRideGroupStore.getState().lastNote;
                    setMsg(
                      "error" in out
                        ? platzNote(out.error, lang)
                        : out.onServer
                          ? g.joined(out.title)
                          : g.joinNotOnServer(
                              platzNote(note ?? LOCAL_ONLY_NOTE, lang),
                            ),
                    );
                    void pullCloud();
                  });
                }}
              >
                {signedIn ? g.join : g.joinLocalCta}
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

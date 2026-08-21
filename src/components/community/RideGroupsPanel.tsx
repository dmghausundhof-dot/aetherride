"use client";

import { useEffect, useState } from "react";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import Link from "next/link";
import {
  canJoinByTypedCode,
  listedPublicJoinGroups,
} from "@/lib/community/rideGroup";
import {
  createStartMax,
  defaultCustomStart,
  formatCreateCustomStartChip,
  resolveCreateStart,
  resolveCreateWindow,
  startFromPreset,
  startOfLocalDay,
  toDateTimeLocalValue,
  type CreateStartPreset,
} from "@/lib/community/rideGroupCreateTime";
import {
  catalogTourAsSaved,
  listMineForGroupCreate,
  listNearbyCatalogForGroupCreate,
  resolveGroupPickerOrigin,
  savedIdsForGroupPicker,
} from "@/lib/community/rideGroupPicker";
import {
  importMemberTourFromInvite,
  tourForInviteGroup,
} from "@/lib/community/groupMemberTour";
import { useAppStore } from "@/store/useAppStore";
import {
  fetchPublicRideGroups,
  isCloudFail,
  rideGroupHasSession,
} from "@/lib/community/rideGroupCloud";
import type { VisibilityScope } from "@/lib/tours/routeVisibility";
import {
  decodeGroupInvite,
  encodeGroupInvite,
  groupInviteHttps,
  parsePastedGroupJoin,
  publicProfileShareUrl,
} from "@/lib/community/rideGroupInvite";
import {
  friendUnnamedNumbers,
  isRideGroupSelf,
  listedRideGroups,
  memberRosterLine,
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
import { MappeSectionLabel } from "@/components/tours/MappeSectionLabel";

function chipClass(on: boolean): string {
  return `rounded-lg border px-2 py-1.5 text-xs ${
    on ? "border-accent text-accent" : "border-border text-foreground"
  }`;
}

function inviteUrl(group: RideGroup, savedRoutes: SavedRoute[]): string {
  const route = savedRoutes.find((r) => r.id === group.savedRouteId);
  return groupInviteHttps(
    group.id || group.joinCode,
    encodeGroupInvite(group, tourForInviteGroup(group, route))
  );
}

function shareText(
  group: RideGroup,
  g: PlatzCopy,
  lang: ChromeLang,
  savedRoutes: SavedRoute[]
): string {
  const url = inviteUrl(group, savedRoutes);
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
  if (canJoinByTypedCode(group.visibility ?? "private") && group.joinCode) {
    lines.push(`${g.joinCodeField}: ${group.joinCode}`);
  }
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
  savedRoutes: SavedRoute[]
) {
  const url = inviteUrl(group, savedRoutes);
  const text = shareText(group, g, lang, savedRoutes);
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
  await copyInvite(group, setMsg, g, savedRoutes);
}

async function copyInvite(
  group: RideGroup,
  setMsg: (m: string) => void,
  g: PlatzCopy,
  savedRoutes: SavedRoute[]
) {
  const url = inviteUrl(group, savedRoutes);
  try {
    await navigator.clipboard.writeText(url);
    setMsg(g.copiedInvite);
  } catch {
    setMsg(url);
  }
}

async function copyJoinCode(
  group: RideGroup,
  setMsg: (m: string) => void,
  g: PlatzCopy,
) {
  try {
    await navigator.clipboard.writeText(group.joinCode);
    setMsg(g.copiedCode);
  } catch {
    setMsg(group.joinCode);
  }
}

export function RideGroupsPanel({
  savedRoutes,
  initialRouteId,
  origin,
  originKind,
  onCreated,
}: {
  savedRoutes: SavedRoute[];
  /** Kept for callers — public groups are always listed, not only under Shared. */
  visibility?: VisibilityScope;
  initialRouteId?: string | null;
  origin?: { lat: number; lng: number } | null;
  originKind?: "gps" | "map" | null;
  onCreated?: () => void;
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
  const joinListedLocal = useRideGroupStore((s) => s.joinListedLocal);
  const createGroupAsync = useRideGroupStore((s) => s.createGroupAsync);
  const setLiveOptIn = useRideGroupStore((s) => s.setLiveOptIn);
  const setVisibilityAsync = useRideGroupStore((s) => s.setVisibilityAsync);
  const leaveGroupAsync = useRideGroupStore((s) => s.leaveGroupAsync);
  const extendWindowAsync = useRideGroupStore((s) => s.extendWindowAsync);
  const pullCloud = useRideGroupStore((s) => s.pullCloud);
  const publicProfile = useCommunityStore((s) => s.publicProfile);
  const selfIds = { localUserId, cloudUserId };
  const selfLabel = publicProfile.enabled
    ? publicProfile.displayName.trim() ||
      (publicProfile.handle ? `@${publicProfile.handle}` : g.you)
    : g.you;
  const [msg, setMsg] = useState<string | null>(null);
  const [picked, setPicked] = useState(initialRouteId ?? "");
  const [listing, setListing] = useState<"private" | "public">("private");
  const [startPreset, setStartPreset] = useState<CreateStartPreset>("now");
  const [startsLocal, setStartsLocal] = useState("");
  const [durationH, setDurationH] = useState(3);
  const [durationIsCustom, setDurationIsCustom] = useState(false);
  const [durationCustomRaw, setDurationCustomRaw] = useState("");
  const [extendFor, setExtendFor] = useState<string | null>(null);
  const [extendEndLocal, setExtendEndLocal] = useState("");
  const [meeting, setMeeting] = useState("");
  const [joinPaste, setJoinPaste] = useState("");
  const [timeOpen, setTimeOpen] = useState(false);
  const [signedIn, setSignedIn] = useState(true);
  const [publicGroups, setPublicGroups] = useState<RideGroup[]>([]);
  const [foldOpen, setFoldOpen] = useState<boolean | null>(null);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const resolvedOrigin = resolveGroupPickerOrigin({
    gps: originKind === "map" ? null : origin,
    map: originKind === "map" ? origin : null,
    saved: savedRoutes,
  });
  const mine = listMineForGroupCreate(savedRoutes);
  const nearbyCatalog = listNearbyCatalogForGroupCreate({
    origin: resolvedOrigin,
    excludeIds: savedIdsForGroupPicker(mine),
  });
  const nearbyRoutes = nearbyCatalog.map(catalogTourAsSaved);
  const attachable = [...mine, ...nearbyRoutes];
  const open = listedRideGroups(groups);
  const expanded = foldOpen ?? Boolean(initialRouteId?.trim());
  const mineIds = new Set(open.map((group) => group.id));
  const listedPublic = listedPublicJoinGroups(publicGroups, mineIds);
  const shownNote = lastNote ? platzNote(lastNote, lang) : "";
  const preview = resolveCreateWindow({
    startPreset,
    customStartLocal: startsLocal,
    durationIsCustom,
    durationH,
    durationCustomRaw,
  });
  const previewStart =
    !("error" in preview)
      ? preview.start
      : resolveCreateStart({ startPreset, customStartLocal: startsLocal });
  const previewEnd =
    !("error" in preview)
      ? preview.end
      : new Date(previewStart.getTime() + durationH * 3_600_000);
  const previewWhen = formatPlatzGroupWhen(
    previewStart.toISOString(),
    previewEnd.toISOString(),
    lang,
  );

  useEffect(() => {
    void pullCloud();
    void rideGroupHasSession().then(setSignedIn);
  }, [pullCloud]);
  useEffect(() => {
    const id = initialRouteId?.trim();
    if (id) {
      setPicked(id);
      setFoldOpen(true);
    }
  }, [initialRouteId]);
  useEffect(() => {
    void fetchPublicRideGroups().then((out) => {
      if (!isCloudFail(out)) setPublicGroups(out.groups);
    });
  }, []);

  return (
    <section
      id="group-create"
      className="mt-10 rounded-2xl border border-border bg-surface px-3 py-3"
    >
      <MappeSectionLabel
        glyph="meet"
        count={open.length > 0 ? open.length : undefined}
        expanded={expanded}
        onToggle={() => setFoldOpen(!expanded)}
      >
        {hof.togetherOut}
      </MappeSectionLabel>
      {expanded ? (
      <>
      <p className="mb-3 text-xs text-text-secondary">{g.inviteHint}</p>
      {initialRouteId ? (
        <p
          className="mb-3 rounded-xl border border-accent/40 bg-accent/10 px-3 py-2 text-xs text-foreground"
          data-testid="group-create-ready"
        >
          {g.groupCreateReady}
        </p>
      ) : null}
      {resolvedOrigin?.kind !== "gps" ? (
        <p className="mb-3 text-[11px] text-text-secondary">
          {resolvedOrigin ? g.nearbyFromMap : g.nearbyNeedGps}
        </p>
      ) : null}
      <div
        className={`mb-3 space-y-2 ${
          initialRouteId ? "rounded-xl ring-2 ring-accent/50 p-2" : ""
        }`}
      >
        <div className="flex flex-wrap items-center gap-2">
        <select
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs text-text-secondary"
          value={picked}
          onChange={(e) => setPicked(e.target.value)}
        >
          <option value="">{g.pickTour}</option>
          {mine.length > 0 ? (
            <optgroup label={g.pickMine}>
              {mine.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                </option>
              ))}
            </optgroup>
          ) : null}
          {nearbyRoutes.length > 0 ? (
            <optgroup label={g.pickNearby}>
              {nearbyRoutes.map((r) => (
                <option key={`near-${r.id}`} value={r.id}>
                  {r.name}
                </option>
              ))}
            </optgroup>
          ) : null}
        </select>
        <Link
          href="/discover?panel=plan&asGroup=1"
          className="text-[11px] font-medium text-text-secondary"
        >
          {g.planAsGroup}
        </Link>
        <select
          className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs text-text-secondary"
          value={listing}
          onChange={(e) =>
            setListing(e.target.value === "public" ? "public" : "private")
          }
        >
          <option value="private">{g.visPrivate}</option>
          <option value="public">{g.visPublic}</option>
        </select>
        </div>
        <button
          type="button"
          data-testid="platz-create-time"
          className="w-full py-1 text-left"
          onClick={() => setTimeOpen((o) => !o)}
        >
          <p className="truncate text-sm font-semibold">{previewWhen}</p>
          <p className="text-[11px] text-text-secondary">{g.timeTapHint}</p>
        </button>
        {timeOpen ? (
          <div
            data-testid="platz-create-time-editor"
            className="w-full space-y-2 rounded-lg border border-border px-2.5 py-2"
          >
            <p className="text-[11px] text-text-secondary">{g.startLabel}</p>
            <div className="flex flex-wrap gap-2">
              {(
                [
                  ["now", g.startNow],
                  ["1h", g.startIn1h],
                  ["18", g.startToday18],
                  ["10", g.startTomorrow10],
                ] as const
              ).map(([preset, label]) => (
                <button
                  key={preset}
                  type="button"
                  className={chipClass(startPreset === preset)}
                  onClick={() => {
                    setStartPreset(preset);
                    setStartsLocal(toDateTimeLocalValue(startFromPreset(preset)));
                  }}
                >
                  {label}
                </button>
              ))}
              <button
                type="button"
                data-testid="platz-start-custom"
                className={chipClass(startPreset === "custom")}
                onClick={() => {
                  setStartPreset("custom");
                  if (!startsLocal) {
                    setStartsLocal(toDateTimeLocalValue(defaultCustomStart()));
                  }
                }}
              >
                {startPreset === "custom" && startsLocal
                  ? formatCreateCustomStartChip(new Date(startsLocal))
                  : g.startCustom}
              </button>
            </div>
            {startPreset === "custom" ? (
              <input
                type="datetime-local"
                data-testid="platz-start-custom-input"
                aria-label={g.startCustom}
                min={toDateTimeLocalValue(startOfLocalDay())}
                max={toDateTimeLocalValue(createStartMax())}
                className="rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
                value={startsLocal}
                onChange={(e) => setStartsLocal(e.target.value)}
              />
            ) : null}
            <p className="text-[11px] text-text-secondary">{g.durationLabel}</p>
            <div className="flex flex-wrap gap-2">
              {([2, 3, 4] as const).map((h) => (
                <button
                  key={h}
                  type="button"
                  className={chipClass(!durationIsCustom && durationH === h)}
                  onClick={() => {
                    setDurationH(h);
                    setDurationIsCustom(false);
                  }}
                >
                  {h} h
                </button>
              ))}
              <button
                type="button"
                data-testid="platz-duration-custom"
                className={chipClass(durationIsCustom)}
                onClick={() => setDurationIsCustom(true)}
              >
                {g.durationCustom}
              </button>
            </div>
            {durationIsCustom ? (
              <input
                type="number"
                min={0.25}
                max={12}
                step={0.25}
                inputMode="decimal"
                data-testid="platz-duration-hours"
                aria-label={g.durationCustom}
                placeholder={g.durationHoursHint}
                className="w-28 rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
                value={durationCustomRaw}
                onChange={(e) => setDurationCustomRaw(e.target.value)}
              />
            ) : null}
          </div>
        ) : null}
        <input
          type="text"
          maxLength={80}
          placeholder={g.meetingPlaceholder}
          className="w-full rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          value={meeting}
          onChange={(e) => setMeeting(e.target.value)}
        />
        <button
          type="button"
          className="w-full rounded-xl bg-accent px-3 py-2.5 text-sm font-semibold text-on-accent"
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
            const window = resolveCreateWindow({
              startPreset,
              customStartLocal: startsLocal,
              durationIsCustom,
              durationH,
              durationCustomRaw,
            });
            if ("error" in window) {
              setMsg(g.extendInvalid);
              return;
            }
            void createGroupAsync({
              route,
              displayLabel: selfLabel,
              visibility: listing,
              startsAt: window.start.toISOString(),
              durationHours: window.durationHours,
              meetingPoint: meeting.trim() || undefined,
            }).then((out) => {
              const note = useRideGroupStore.getState().lastNote;
              setMsg(
                "error" in out
                  ? platzNote(out.error, lang)
                  : g.created(note ? platzNote(note, lang) : null),
              );
              if (!("error" in out)) {
                onCreated?.();
                void shareInvite(out, setMsg, g, lang, savedRoutes);
              }
            });
          }}
        >
          {g.createGroup}
        </button>
        <p className="w-full text-[11px] text-text-secondary">{g.windowCapHint}</p>
      </div>
      {!signedIn ? (
        <p className="mb-3 text-xs text-warning">
          <Link href="/profile" className="font-semibold text-accent">
            {chrome.signIn}
          </Link>
          {" — "}
          {g.joinSignInFirst}
        </p>
      ) : null}
      <div className="mb-3 flex flex-wrap items-end gap-2">
        <input
          type="text"
          data-testid="platz-join-field"
          value={joinPaste}
          onChange={(e) => setJoinPaste(e.target.value)}
          placeholder={g.joinField}
          className="min-w-[12rem] flex-1 rounded-lg border border-border bg-background px-3 py-2 text-sm"
        />
        <button
          type="button"
          data-testid="platz-join-submit"
          className="rounded-xl border border-border px-3 py-2 text-sm font-semibold text-foreground"
          onClick={() => {
            const parsed = parsePastedGroupJoin(joinPaste.trim());
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
              if (!("error" in out) && parsed.token) {
                const entry = importMemberTourFromInvite({
                  payload: decodeGroupInvite(parsed.token),
                  existing: savedRoutes,
                });
                if (entry) saveRoute(entry);
              }
              setJoinPaste("");
              void pullCloud();
            });
          }}
        >
          {g.joinWithLink}
        </button>
      </div>
      <p className="mb-3 text-[11px] text-text-secondary">{g.joinHint}</p>
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
            const showCode =
              host && canJoinByTypedCode(group.visibility ?? "private");
            const when = formatPlatzGroupWhen(
              group.startWindowStart,
              group.startWindowEnd,
              lang,
            );
            return (
              <li
                key={group.id}
                className="rounded-xl border border-border bg-surface px-4 py-3"
              >
                <div className="flex items-baseline justify-between gap-2">
                  <p className="truncate text-base font-bold">{group.title}</p>
                  <p className="shrink-0 text-[11px] font-medium text-text-secondary">
                    {group.visibility === "public" ? g.visPublic : g.visPrivate}
                  </p>
                </div>
                {host ? (
                  <button
                    type="button"
                    data-testid={`platz-group-time-${group.id}`}
                    className="mt-1.5 w-full text-left"
                    onClick={() => {
                      if (extendFor === group.id) {
                        setExtendFor(null);
                        return;
                      }
                      setExtendFor(group.id);
                      const now = new Date();
                      const end = new Date(group.startWindowEnd);
                      const cap = new Date(now.getTime() + 12 * 60 * 60 * 1000);
                      const seed =
                        end.getTime() > now.getTime() && end.getTime() <= cap.getTime()
                          ? end
                          : new Date(now.getTime() + 60 * 60 * 1000);
                      setExtendEndLocal(toDateTimeLocalValue(seed));
                    }}
                  >
                    <p className="text-sm font-semibold">{when}</p>
                    <p className="text-[11px] text-text-secondary">
                      {g.timeTapHint}
                    </p>
                  </button>
                ) : (
                  <p className="mt-1.5 text-sm font-semibold">{when}</p>
                )}
                {group.meetingPoint ? (
                  <p className="mt-1 text-xs text-text-secondary">
                    {group.meetingPoint}
                  </p>
                ) : null}
                {roster.length > 0 ? (
                  <p className="mt-1 truncate text-xs text-text-secondary">
                    {(() => {
                      const numbers = friendUnnamedNumbers(
                        roster,
                        [localUserId, cloudUserId].filter(Boolean) as string[]
                      );
                      return roster
                        .map((m) =>
                          memberRosterLine({
                            displayLabel: m.displayLabel,
                            isHost: m.userId === group.hostUserId,
                            isSelf: isRideGroupSelf(selfIds, m.userId),
                            friendN: numbers[m.userId],
                            host: g.host,
                            guest: g.guest,
                            you: g.you,
                            friendLabel: g.friendN,
                          })
                        )
                        .join("  ·  ");
                    })()}
                  </p>
                ) : null}
                {extendFor === group.id && host ? (
                  <div className="mt-2 flex flex-wrap items-center gap-2">
                    {(
                      [
                        [0.5, g.extend30m],
                        [1, g.extend1h],
                        [2, g.extend2h],
                      ] as const
                    ).map(([hours, label]) => (
                      <button
                        key={hours}
                        type="button"
                        className="text-xs font-medium text-text-secondary"
                        onClick={() =>
                          void extendWindowAsync(group.id, { hours }).then(
                            (ok) => {
                              const note =
                                useRideGroupStore.getState().lastNote;
                              setMsg(
                                ok
                                  ? platzNote(note, lang) || g.windowExtended
                                  : platzNote(note, lang) || g.extendInvalid,
                              );
                              if (ok) setExtendFor(null);
                            },
                          )
                        }
                      >
                        {label}
                      </button>
                    ))}
                    <input
                      type="datetime-local"
                      aria-label={g.extendCustomEnd}
                      min={toDateTimeLocalValue(new Date())}
                      max={toDateTimeLocalValue(
                        new Date(Date.now() + 12 * 60 * 60 * 1000),
                      )}
                      className="rounded-lg border border-border bg-background px-2 py-1 text-xs"
                      value={extendEndLocal}
                      onChange={(e) => setExtendEndLocal(e.target.value)}
                    />
                    <button
                      type="button"
                      className="text-xs font-medium text-text-secondary"
                      onClick={() => {
                        if (!extendEndLocal) return;
                        const iso = new Date(extendEndLocal).toISOString();
                        void extendWindowAsync(group.id, {
                          newEnd: iso,
                        }).then((ok) => {
                          const note = useRideGroupStore.getState().lastNote;
                          setMsg(
                            ok
                              ? platzNote(note, lang) || g.windowExtended
                              : platzNote(note, lang) || g.extendInvalid,
                          );
                          if (ok) setExtendFor(null);
                        });
                      }}
                    >
                      {g.extendCustomEnd}
                    </button>
                    <span className="text-[11px] text-text-secondary">
                      {g.extendCapHint}
                    </span>
                  </div>
                ) : null}
                {host ? (
                  <button
                    type="button"
                    className="mt-3 w-full rounded-xl bg-accent px-3 py-2.5 text-sm font-semibold text-on-accent"
                    onClick={() => void shareInvite(group, setMsg, g, lang, savedRoutes)}
                  >
                    {g.invite}
                  </button>
                ) : null}
                <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1">
                  {showCode ? (
                    <span
                      data-testid={`platz-host-code-${group.id}`}
                      className="font-mono text-[11px] font-semibold tracking-wide text-text-secondary"
                    >
                      {group.joinCode}
                    </span>
                  ) : null}
                  {host || group.onServer ? (
                    <button
                      type="button"
                      className="text-[11px] font-medium text-text-secondary"
                      onClick={() => void copyInvite(group, setMsg, g, savedRoutes)}
                    >
                      {showCode ? g.copyLink : g.shareLink}
                    </button>
                  ) : null}
                  {showCode ? (
                    <button
                      type="button"
                      className="text-[11px] font-medium text-text-secondary"
                      onClick={() => void copyJoinCode(group, setMsg, g)}
                    >
                      {g.copyCode}
                    </button>
                  ) : null}
                  <button
                    type="button"
                    className="text-[11px] font-medium text-text-secondary"
                    onClick={() => void leaveGroupAsync(group.id)}
                  >
                    {host ? g.dissolve : g.leave}
                  </button>
                  {host ? (
                    <button
                      type="button"
                      className="text-[11px] font-medium text-text-secondary"
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
                  <label className="mt-2 flex items-center justify-between gap-2 text-[12px] text-text-secondary">
                    <span>{g.shareInRide}</span>
                    <input
                      type="checkbox"
                      checked={Boolean(me?.liveOptIn)}
                      onChange={() => {
                        const next = !me?.liveOptIn;
                        setLiveOptIn(group.id, next);
                        if (next) setMsg(g.pinsHint);
                      }}
                    />
                  </label>
                ) : null}
              </li>
            );
          })}
          {listedPublic.map((group) => (
            <li
              key={`pub-${group.id}`}
              className="flex items-center justify-between gap-3 rounded-xl border border-border bg-surface px-4 py-3"
            >
              <div className="min-w-0">
                <p className="truncate text-base font-bold">{group.title}</p>
                <p className="mt-1 text-sm font-semibold">
                  {formatPlatzGroupWhen(
                    group.startWindowStart,
                    group.startWindowEnd,
                    lang,
                  )}
                </p>
                <p className="text-[11px] text-text-secondary">{g.visPublic}</p>
              </div>
              <button
                type="button"
                className="shrink-0 rounded-xl bg-accent px-3 py-2 text-sm font-semibold text-on-accent"
                onClick={() => {
                  if (!signedIn) {
                    const out = joinListedLocal(group);
                    setMsg(
                      "error" in out
                        ? platzNote(out.error, lang)
                        : g.joinNotOnServer(g.joinSignInFirst),
                    );
                    return;
                  }
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
        </>
      ) : null}
    </section>
  );
}

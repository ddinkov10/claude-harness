#!/usr/bin/env node
// Minimal Claude Code statusline. Reads stdin JSON, prints one line.
// Standalone: node built-ins only, no deps, no OMC.
// Schema fields: model.display_name, context_window.{used_percentage,
// current_usage.*, context_window_size}, rate_limits.{five_hour,seven_day}.
// {used_percentage,resets_at}, cost.total_cost_usd, effort.level,
// workspace.current_dir, cwd.

import { execFileSync } from "node:child_process";
import { basename } from "node:path";

const ansi = (code, s) => `\x1b[${code}m${s}\x1b[0m`;
const dim = (s) => ansi("2", s);
const bold = (s) => ansi("1", s);
const cyan = (s) => ansi("36", s);
const blue = (s) => ansi("34", s);
const magenta = (s) => ansi("35", s);
const green = (s) => ansi("32", s);
const yellow = (s) => ansi("33", s);
const red = (s) => ansi("31", s);

async function readStdin() {
  if (process.stdin.isTTY) return null;
  const chunks = [];
  process.stdin.setEncoding("utf8");
  for await (const ch of process.stdin) chunks.push(ch);
  const raw = chunks.join("").trim();
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function modelName(s) {
  return s.model?.display_name ?? s.model?.id ?? "Claude";
}

// Reasoning effort badge (low|medium|high|xhigh|max). Absent when the model
// has no effort param; reflects live /effort changes.
function effortSegment(s) {
  const level = s.effort?.level;
  if (!level) return null;
  return dim("eff:") + cyan(level);
}

// Prefer Claude Code's native percentage; fall back to tokens / window size.
function contextPercent(s) {
  const cw = s.context_window ?? {};
  const native = cw.used_percentage;
  if (typeof native === "number" && native > 0) return Math.min(100, Math.round(native));
  const size = cw.context_window_size;
  if (size > 0) {
    const u = cw.current_usage ?? {};
    const tokens =
      (u.input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0) + (u.cache_read_input_tokens ?? 0);
    if (tokens > 0) return Math.min(100, Math.round((tokens / size) * 100));
  }
  return 0;
}

// Colorize a percentage by severity. txt lets callers add a label/suffix.
function colorPct(pct, txt = `${pct}%`) {
  if (pct >= 80) return red(txt);
  if (pct >= 50) return yellow(txt);
  return green(txt);
}

// resets_at may be epoch seconds, epoch ms, or ISO string (mirror Claude Code).
function parseResetDate(value) {
  if (value == null) return null;
  const num =
    typeof value === "number" ? value : typeof value === "string" && value.trim() !== "" ? Number(value) : NaN;
  if (Number.isFinite(num)) {
    const ms = Math.abs(num) < 1e12 ? num * 1000 : num;
    const d = new Date(ms);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  if (typeof value === "string") {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

// Compact time-until-reset: "2d11h" / "3h45m" / "12m". "" if unknown.
function fmtReset(value) {
  const d = parseResetDate(value);
  if (!d) return "";
  let secs = Math.round((d.getTime() - Date.now()) / 1000);
  if (secs <= 0) return "(0m)";
  const days = Math.floor(secs / 86400);
  secs -= days * 86400;
  const hrs = Math.floor(secs / 3600);
  secs -= hrs * 3600;
  const mins = Math.floor(secs / 60);
  const body = days >= 1 ? `${days}d${hrs}h` : hrs >= 1 ? `${hrs}h${mins}m` : `${mins}m`;
  return `(${body})`;
}

// "5h:34%(3h45m) wk:73%(2d11h)" — omits a window when its data is absent.
function rateSegment(s) {
  const rl = s.rate_limits;
  if (!rl) return null;
  const parts = [];
  const add = (label, slot) => {
    const pct = slot?.used_percentage;
    if (typeof pct !== "number") return;
    const rounded = Math.round(pct);
    parts.push(dim(`${label}:`) + colorPct(rounded) + dim(fmtReset(slot.resets_at)));
  };
  add("5h", rl.five_hour);
  add("wk", rl.seven_day);
  return parts.length ? parts.join(" ") : null;
}

// Session spend (client-side estimate). Omitted when cost is unavailable.
function costSegment(s) {
  const usd = s.cost?.total_cost_usd;
  if (typeof usd !== "number") return null;
  return dim(`$${usd.toFixed(2)}`);
}

function gitSegment(cwd) {
  const run = (args) =>
    execFileSync("git", ["-C", cwd, ...args], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 500,
    }).trim();
  try {
    const branch = run(["rev-parse", "--abbrev-ref", "HEAD"]);
    if (!branch) return null;
    let dirty = "";
    try {
      if (run(["status", "--porcelain"])) dirty = yellow("*");
    } catch {
      // ignore: dirty marker is best-effort
    }
    let sync = "";
    try {
      // local refs only, no fetch; throws when no upstream is configured.
      const [behind, ahead] = run(["rev-list", "--left-right", "--count", "@{upstream}...HEAD"])
        .split(/\s+/)
        .map(Number);
      sync = ahead === 0 && behind === 0 ? green("✓") : yellow("≠");
    } catch {
      sync = dim("∅"); // no upstream set
    }
    return magenta(branch) + dirty + sync;
  } catch {
    return null; // not a git repo
  }
}

const sep = dim(" │ ");
const s = (await readStdin()) ?? {};
const cwd = s.workspace?.current_dir ?? s.cwd ?? process.cwd();

const segs = [bold(cyan(modelName(s)))];
const effort = effortSegment(s);
if (effort) segs.push(effort);
const rate = rateSegment(s);
if (rate) segs.push(rate);
const cost = costSegment(s);
if (cost) segs.push(cost);
segs.push(dim("ctx:") + colorPct(contextPercent(s)));
segs.push(blue(basename(cwd)));
const git = gitSegment(cwd);
if (git) segs.push(git);

process.stdout.write(segs.join(sep));

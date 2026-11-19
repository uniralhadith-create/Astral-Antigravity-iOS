#!/usr/bin/env node
import { WebSocketServer, WebSocket } from "ws";
import { spawn, execFileSync } from "node:child_process";
import crypto from "node:crypto";
import os from "node:os";
import fs from "node:fs";
import path from "node:path";
import qrcode from "qrcode-terminal";

const PORT = Number(process.env.ASTRAL_PORT || 7788);
const TOKEN = process.env.ASTRAL_TOKEN || crypto.randomBytes(16).toString("hex");
const WORKSPACE = process.cwd();
const HOST_NAME = os.hostname();

function getLocalIP(): string {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === "IPv4" && !net.internal) return net.address;
    }
  }
  return "127.0.0.1";
}

function listWorkspaceFiles(dir: string, depth = 0): any[] {
  if (depth > 2) return [];
  const ignore = new Set(["node_modules", ".git", ".build", "build", "dist", ".next"]);
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const results: any[] = [];

  for (const entry of entries) {
    if (ignore.has(entry.name)) continue;
    const full = path.join(dir, entry.name);
    const rel = path.relative(WORKSPACE, full);
    if (entry.isDirectory()) {
      results.push({ id: rel, name: entry.name, path: rel, isDirectory: true });
      results.push(...listWorkspaceFiles(full, depth + 1));
    } else {
      let content: string | undefined;
      try {
        const stat = fs.statSync(full);
        if (stat.size < 64_000) content = fs.readFileSync(full, "utf8");
      } catch {}
      results.push({ id: rel, name: entry.name, path: rel, isDirectory: false, content });
    }
  }
  return results.slice(0, 120);
}

function git(args: string[]): string {
  try {
    return execFileSync("git", args, { cwd: WORKSPACE, encoding: "utf8" });
  } catch {
    return "";
  }
}

function getGitDiffs(): any[] {
  const raw = git(["diff", "--numstat"]).trim();
  if (!raw) return [];
  return raw.split("\n").map((line) => {
    const [add, del, ...rest] = line.split("\t");
    const filePath = rest.join("\t");
    const patch = git(["diff", "--", filePath]).slice(0, 8000);
    return {
      id: filePath,
      filePath,
      additions: Number(add) || 0,
      deletions: Number(del) || 0,
      patch,
    };
  });
}

function getGitBranch(): string {
  const branch = git(["rev-parse", "--abbrev-ref", "HEAD"]).trim();
  return branch || "main";
}

const wss = new WebSocketServer({ port: PORT });

wss.on("connection", (ws: WebSocket, req) => {
  const url = new URL(req.url || "/", `http://localhost:${PORT}`);
  if (url.searchParams.get("token") !== TOKEN) {
    ws.close(1008, "Invalid pairing token");
    return;
  }

  const send = (payload: Record<string, unknown>) => {
    if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(payload));
  };

  const pipeAgent = (child: ReturnType<typeof spawn>) => {
    let progress = 0.25;
    const onChunk = (d: Buffer) => {
      progress = Math.min(0.92, progress + 0.08);
      send({
        type: "agent.chunk",
        chunk: d.toString(),
        step: "Antigravity ينفّذ المهمة...",
        progress,
      });
    };
    if (child.stdout) child.stdout.on("data", onChunk);
    if (child.stderr) child.stderr.on("data", (d: Buffer) => send({ type: "terminal.output", line: d.toString(), isError: true }));
    child.on("error", (err) => {
      send({ type: "terminal.output", line: `CLI error: ${err.message}`, isError: true });
      send({ type: "agent.done", summary: "تعذر تشغيل Antigravity/Gemini CLI على جهازك", changedFiles: [] });
    });
    child.on("close", () => {
      const diffs = getGitDiffs();
      send({
        type: "agent.done",
        summary: `اكتملت مهمة Antigravity (${diffs.length} ملفات معدّلة)`,
        changedFiles: diffs.map((d) => d.filePath),
      });
    });
  };

  send({ type: "hello", hostName: HOST_NAME, workspace: WORKSPACE });

  ws.on("message", (raw) => {
    let msg: any;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }

    switch (msg.type) {
      case "workspace.sync": {
        send({
          type: "workspace.projects",
          projects: [
            {
              id: "local-active",
              name: path.basename(WORKSPACE),
              path: WORKSPACE,
              mode: "local",
              branch: getGitBranch(),
              previewURL: process.env.ASTRAL_PREVIEW_URL || "http://localhost:3000",
            },
          ],
        });
        send({ type: "files.tree", files: listWorkspaceFiles(WORKSPACE) });
        send({ type: "git.diffs", diffs: getGitDiffs() });
        break;
      }

      case "files.list":
        send({ type: "files.tree", files: listWorkspaceFiles(WORKSPACE) });
        break;

      case "git.diff":
        send({ type: "git.diffs", diffs: getGitDiffs() });
        break;

      case "git.action": {
        try {
          if (msg.action === "undo") execFileSync("git", ["checkout", "--", "."], { cwd: WORKSPACE });
          if (msg.action === "commit") {
            execFileSync("git", ["add", "-A"], { cwd: WORKSPACE });
            const message = String(msg.message || "Astral Antigravity update").slice(0, 500);
            execFileSync("git", ["commit", "-m", message], { cwd: WORKSPACE });
          }
          if (msg.action === "push") execFileSync("git", ["push"], { cwd: WORKSPACE });
          if (msg.action === "open_pr") {
            try {
              execFileSync("gh", ["pr", "create", "--fill"], { cwd: WORKSPACE });
            } catch {}
          }
          send({ type: "terminal.output", line: `✓ Git action '${msg.action}' completed`, isError: false });
          send({ type: "git.diffs", diffs: getGitDiffs() });
        } catch (err: any) {
          send({ type: "terminal.output", line: `Git error: ${err.message}`, isError: true });
        }
        break;
      }

      case "terminal.exec": {
        const child = spawn(msg.command, { cwd: WORKSPACE, shell: true });
        child.stdout.on("data", (d) => send({ type: "terminal.output", line: d.toString(), isError: false }));
        child.stderr.on("data", (d) => send({ type: "terminal.output", line: d.toString(), isError: true }));
        child.on("close", (code) =>
          send({ type: "terminal.output", line: `[exit ${code ?? 0}]`, isError: (code ?? 0) !== 0 })
        );
        break;
      }

      case "agent.prompt": {
        // Prefer Google Antigravity CLI if installed, otherwise fall back to Gemini CLI
        const promptText = String(msg.prompt || "");
        const binary = process.env.ASTRAL_CLI_BIN || "antigravity";
        const child = spawn(binary, ["chat", "--non-interactive", promptText], { cwd: WORKSPACE, shell: false });
        child.on("error", () => {
          // antigravity CLI not installed — fall back to Gemini CLI without a shell
          const gemini = spawn("gemini", ["-p", promptText], { cwd: WORKSPACE, shell: false });
          pipeAgent(gemini);
        });
        if (child.stdout) pipeAgent(child);
        break;
      }
    }
  });
});

const ip = getLocalIP();
const wsUrl = `ws://${ip}:${PORT}`;
const magicLink = `astral://pair?ws=${encodeURIComponent(wsUrl)}&token=${TOKEN}&name=${encodeURIComponent(HOST_NAME)}`;

console.log("\n✨ Astral Antigravity Connector v1.6 (100% Free & Local)\n");
console.log(`Workspace : ${WORKSPACE}`);
console.log(`WebSocket : ${wsUrl}`);
console.log(`Magic Link: ${magicLink}\n`);
console.log("Scan this QR Code inside the Astral iOS App:\n");
qrcode.generate(magicLink, { small: true });

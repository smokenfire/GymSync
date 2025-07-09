/**
 * GymSync Presence Desktop Client
 * Uses Electron + discord-rich-presence + Discord OAuth2
 * Supports custom RPC title and dynamic largeImageKey based on activity
 * Now starts automatically when the PC boots (auto-launch enabled)
 */
require('dotenv').config();
const clientId = "1391871101734223912";

const { app, BrowserWindow, Tray, Menu, dialog } = require("electron");
const prompt = require('electron-prompt');
const rpc = require("discord-rich-presence")(clientId);
const axios = require("axios");
const path = require("path");
const AutoLaunch = require('auto-launch');

// === Configuration ===
const backendUrl = process.env.BACKEND_URL || "http://localhost:3000/api/v1/status";
const redirectUri = process.env.REDIRECT_URI || "http://localhost:3000/success";

// === Customizable RPC title ===
let rpcTitle = "GymSync";

let tray = null;
let mainWindow = null;
let discord_id = null;
let access_token = null;
let rpcLoop = null;
let lastPresence = null;

const activityImageMap = {
  "running": "running",      // running.png in Discord assets
  "cycling": "cycling",
  "gym": "gym",
  // is possible to add more activities here
};

function getImageKeyForActivity(activity) {
  if (!activity || typeof activity !== "string") return "gymsync_logo"; // fallback para gymsync_logo
  const key = activity.toLowerCase();
  // Try to match by activity name
  for (const [name, imageKey] of Object.entries(activityImageMap)) {
    if (key.includes(name)) return imageKey;
  }
  // Se não encontrar, retorna fallback gymsync_logo
  return "gymsync_logo";
}

// Logging utility (minimal and concise)
function log(...args) {
  const ts = new Date().toISOString();
  console.log(`[${ts}]`, ...args);
}
function logError(...args) {
  const ts = new Date().toISOString();
  console.error(`[${ts}][ERR]`, ...args);
}

// === Auto-launch configuration ===
const appLauncher = new AutoLaunch({
  name: 'GymSync Presence',
  path: process.execPath,
  isHidden: true, // inicia em background
});

// Função para garantir auto-launch ativo na primeira vez:
function ensureAutoLaunch() {
  appLauncher.isEnabled().then((isEnabled) => {
    if (!isEnabled) {
      appLauncher.enable()
          .then(() => log("Auto-launch ativado! O app vai iniciar junto com o sistema."))
          .catch((err) => logError("Erro ao ativar auto-launch:", err));
    } else {
      log("Auto-launch já está ativo.");
    }
  }).catch((err) => logError("Erro ao checar auto-launch:", err));
}

app.whenReady().then(() => {
  log("App started.");

  // Garante auto-launch:
  ensureAutoLaunch();

  tray = new Tray(path.join(__dirname, "assets", "tray-icon.png"));
  const trayMenu = Menu.buildFromTemplate([
    {
      label: "Show Window",
      click: () => {
        if (mainWindow) {
          mainWindow.show();
        } else {
          createOAuthWindow();
        }
      }
    },
    {
      label: "Set RPC Title...",
      click: async () => {
        setCustomRPCTitle();
      }
    },
    { type: "separator" },
    {
      label: "Quit",
      click: () => {
        app.quit();
      }
    }
  ]);
  tray.setToolTip("GymSync Presence");
  tray.setContextMenu(trayMenu);

  createOAuthWindow();
});

async function setCustomRPCTitle() {
  const win = mainWindow || BrowserWindow.getFocusedWindow();
  const result = await prompt({
    title: 'Set RPC Title',
    label: 'Enter a custom RPC title (default: GymSync):',
    value: rpcTitle,
    inputAttrs: {
      type: 'text'
    },
    type: 'input',
    resizable: false,
    width: 400,
    height: 150,
    alwaysOnTop: true,
    parent: win
  }, win);

  if (result !== null && typeof result === "string") {
    rpcTitle = result.trim() || "GymSync";
    log(`RPC Title set to: ${rpcTitle}`);
  }
}

function createOAuthWindow() {
  if (mainWindow) {
    mainWindow.show();
    return;
  }

  mainWindow = new BrowserWindow({
    width: 600,
    height: 700,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false, // DEV only
      sandbox: false,
    },
  });

  mainWindow.on("close", (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.on("closed", () => {
    mainWindow = null;
  });

  const scope = "identify";
  const responseType = "token";
  const oauthUrl = `https://discord.com/api/oauth2/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(
      redirectUri
  )}&response_type=${responseType}&scope=${scope}`;

  mainWindow.loadURL(oauthUrl);

  // OAuth navigation events
  const wc = mainWindow.webContents;
  const tryHandle = url => handleOAuthRedirect(url);

  wc.on("will-redirect", (e, url) => tryHandle(url));
  wc.on("did-navigate-in-page", (e, url) => tryHandle(url));
  wc.on("will-navigate", (e, url) => tryHandle(url));
  wc.on("did-get-redirect-request", (e, oldURL, newURL) => tryHandle(newURL));
  wc.on("did-redirect-navigation", (e, url) => tryHandle(url));
  wc.on("did-finish-load", () => {});
  wc.on("did-fail-load", (e, code, desc, url) => {
    logError("Failed to load page:", code, desc, url);
  });
}

// Central OAuth redirect handler
async function handleOAuthRedirect(url) {
  if (!url.startsWith(redirectUri)) return;

  const fragment = url.split("#")[1];
  if (!fragment) {
    logError("No token fragment in redirect URL.");
    return;
  }

  const params = new URLSearchParams(fragment);
  access_token = params.get("access_token");
  if (!access_token) {
    logError("Access token not found.");
    return;
  }

  try {
    const user = await axios.get("https://discord.com/api/users/@me", {
      headers: { Authorization: `Bearer ${access_token}` },
    });
    discord_id = user.data.id;
    log(`Authenticated Discord ID: ${discord_id} (${user.data.username}#${user.data.discriminator})`);
    startRPCOnce();

    // Hide window after login
    setTimeout(() => {
      if (mainWindow) mainWindow.hide();
    }, 1500);
  } catch (err) {
    logError("Error getting Discord user data:", err?.message);
  }
}

// Makes sure the RPC loop is started only once
function startRPCOnce() {
  if (startRPCOnce.started) return;
  startRPCOnce.started = true;
  startRPC();
}
startRPCOnce.started = false;

function clearPresence() {
  if (lastPresence) {
    rpc.clearPresence();
    log("Discord presence cleared.");
    lastPresence = null;
  }
}

function startRPC() {
  if (rpcLoop) clearInterval(rpcLoop);

  rpcLoop = setInterval(async () => {
    if (!discord_id) return;

    try {
      const res = await axios.get(`${backendUrl}/${discord_id}`);
      const status = res.data;

      if (!status || !status.activity || typeof status.time !== "number") {
        clearPresence();
        return;
      }

      // If paused, shows presence as "Paused"
      let activity = status.activity;
      let detail = activity;
      if (status.paused) {
        detail = `[⏸️ Paused] ${activity}`;
      }

      const elapsedSeconds = status.time;
      const startTimestamp = status.paused
          ? undefined
          : Math.floor(Date.now() / 1000) - elapsedSeconds;

      const largeImageKey = getImageKeyForActivity(activity);

      // --- smallImageKey, smallImageText, partySize ---
      const smallImageKey = "gymsync_logo"; // must match asset name in Discord Developer Portal
      const smallImageText = "GymSync";

      rpc.updatePresence({
        state: rpcTitle, // Title set by user or default
        details: detail,
        startTimestamp,
        largeImageKey,
        smallImageKey,
        smallImageText,
        party: {
          id: "gymsync-party",
          size: [1, 1],
        },
        instance: false,
      });

      lastPresence = true;
      log(`Updated presence: ${rpcTitle} | ${detail} | image: ${largeImageKey} | small: ${smallImageKey}`);

    } catch (err) {
      // If 404, status does not exist -- clear presence
      if (err.response && err.response.status === 404) {
        clearPresence();
        return;
      }
      logError("Error updating backend status:", err?.message);
    }
  }, 5000);
}

app.on("window-all-closed", (e) => {
  e.preventDefault();
});

app.on("before-quit", () => {
  app.isQuitting = true;
  if (rpcLoop) clearInterval(rpcLoop);
});
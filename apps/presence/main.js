/**
 * GymSync Presence Desktop Client (MacOS compatible)
 * Uses Electron + discord-rpc + Discord OAuth2
 * Supports custom RPC title and dynamic largeImageKey based on activity
 * Now starts automatically when the PC boots (auto-launch enabled)
 */
require('dotenv').config();
const clientId = "1391871101734223912";

const { app, BrowserWindow, Tray, Menu, dialog, nativeImage } = require("electron");
const prompt = require('electron-prompt');
const DiscordRPC = require("discord-rpc");
const axios = require("axios");
const path = require("path");
const AutoLaunch = require('auto-launch');
const os = require('os');

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

// Timer fix
let localStartTimestamp = null;
let lastActivity = null;

// === Discord RPC Setup ===
DiscordRPC.register(clientId);
const rpc = new DiscordRPC.Client({ transport: 'ipc' });

const activityImageMap = {
  "running": "running",
  "cycling": "cycling",
  "gym": "gym",
  // add more activities here
};

function getImageKeyForActivity(activity) {
  if (!activity || typeof activity !== "string") return "gymsync_logo";
  const key = activity.toLowerCase();
  for (const [name, imageKey] of Object.entries(activityImageMap)) {
    if (key.includes(name)) return imageKey;
  }
  return "gymsync_logo";
}

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
  path: process.execPath, // MacOS: process.execPath points to the correct bundle
  isHidden: true,
});

function ensureAutoLaunch() {
  appLauncher.isEnabled().then((isEnabled) => {
    if (!isEnabled) {
      appLauncher.enable()
          .then(() => log("Auto-launch enabled! The app will start with the system."))
          .catch((err) => logError("Error enabling auto-launch:", err));
    } else {
      log("Auto-launch is already enabled.");
    }
  }).catch((err) => logError("Error checking auto-launch:", err));
}

function getTrayIconPath() {
  if (process.platform === "darwin") {
    return path.join(__dirname, "assets", "tray-icon-mac.png"); // provide this icon in assets
  }
  return path.join(__dirname, "assets", "tray-icon.png");
}

function createTray() {
  let iconPath = getTrayIconPath();
  let trayIcon = nativeImage.createFromPath(iconPath);

  if (trayIcon.isEmpty()) {
    trayIcon = nativeImage.createEmpty();
  } else if (process.platform === 'darwin') {
    trayIcon = trayIcon.resize({ width: 18, height: 18 });
    trayIcon.setTemplateImage(true);
  }

  tray = new Tray(trayIcon);
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

  if (process.platform === "darwin") {
    tray.on('click', () => {
      if (mainWindow) {
        mainWindow.show();
      } else {
        createOAuthWindow();
      }
    });
  }
}

app.whenReady().then(() => {
  log("App started.");
  ensureAutoLaunch();
  createTray();
  createOAuthWindow();
});

async function setCustomRPCTitle() {
  const win = mainWindow || BrowserWindow.getFocusedWindow();
  const result = await prompt({
    title: 'Set RPC Title',
    label: 'Enter a custom RPC title (default: GymSync):',
    value: rpcTitle,
    inputAttrs: { type: 'text' },
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
      webSecurity: false,
      sandbox: false,
    },
    show: false,
    title: "GymSync Presence",
  });

  mainWindow.on("close", (event) => {
    if (process.platform === "darwin" && !app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    } else if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  mainWindow.on("closed", () => {
    mainWindow = null;
  });

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  const scope = "identify";
  const responseType = "token";
  const oauthUrl = `https://discord.com/api/oauth2/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(
      redirectUri
  )}&response_type=${responseType}&scope=${scope}`;

  mainWindow.loadURL(oauthUrl);

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
    setTimeout(() => {
      if (mainWindow) mainWindow.hide();
    }, 1500);
  } catch (err) {
    logError("Error getting Discord user data:", err?.message);
  }
}

function startRPCOnce() {
  if (startRPCOnce.started) return;
  startRPCOnce.started = true;
  rpc.login({ clientId })
      .then(() => {
        log("Discord RPC logged in.");
        startRPC();
      })
      .catch(logError);
}
startRPCOnce.started = false;

function clearPresence() {
  if (lastPresence) {
    rpc.clearActivity().catch(() => {});
    log("Discord presence cleared.");
    lastPresence = null;
  }
  lastActivity = null;
  localStartTimestamp = null;
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

      let activity = status.activity;
      let detail = activity;
      if (status.paused) {
        detail = `[⏸️ Paused] ${activity}`;
      }

      // Fix timer: calculate startTimestamp ONLY when activity changes or first time
      if (lastActivity !== activity || localStartTimestamp === null) {
        localStartTimestamp = Math.floor(Date.now() / 1000) - status.time;
        lastActivity = activity;
      }
      const startTimestamp = status.paused ? undefined : localStartTimestamp;

      const largeImageKey = getImageKeyForActivity(activity);

      // DiscordRPC expects partyId, partySize, partyMax at root level
      await rpc.setActivity({
        state: rpcTitle,
        details: detail,
        startTimestamp,
        largeImageKey,
        partyId: "gymsync-party-" + discord_id,
        partySize: 1,
        partyMax: 1,
        instance: false,
        buttons: [
          { label: "Check GymSync", url: "https://github.com/TheusHen/GymSync" }
        ],
      });

      lastPresence = true;
      log(`Updated presence: ${rpcTitle} | ${detail} | image: ${largeImageKey}`);

    } catch (err) {
      if (err.response && err.response.status === 404) {
        clearPresence();
        return;
      }
      logError("Error updating backend status:", err?.message || err);
    }
  }, 5000);
}

app.on("activate", () => {
  if (mainWindow) {
    mainWindow.show();
  } else {
    createOAuthWindow();
  }
});

app.on("window-all-closed", (e) => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("before-quit", () => {
  app.isQuitting = true;
  if (rpcLoop) clearInterval(rpcLoop);
});
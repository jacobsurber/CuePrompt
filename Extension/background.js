// CuePrompt Companion — Background service worker
// Manages the WebSocket connection to the CuePrompt macOS app.

const WS_URL = "ws://localhost:19876";
let ws = null;
let reconnectTimer = null;
let connectionState = "disconnected"; // disconnected | connecting | connected

function connect() {
  if (ws && ws.readyState === WebSocket.OPEN) return;

  connectionState = "connecting";
  broadcastState();

  try {
    ws = new WebSocket(WS_URL);
  } catch (e) {
    connectionState = "disconnected";
    broadcastState();
    scheduleReconnect();
    return;
  }

  ws.onopen = () => {
    connectionState = "connected";
    broadcastState();
    clearReconnectTimer();
  };

  ws.onclose = () => {
    connectionState = "disconnected";
    ws = null;
    broadcastState();
    scheduleReconnect();
  };

  ws.onerror = () => {
    connectionState = "disconnected";
    ws = null;
    broadcastState();
    scheduleReconnect();
  };

  ws.onmessage = (event) => {
    // CuePrompt may send commands in the future (e.g., "next slide").
    // For now, this is a one-way pipe (extension -> app).
    console.log("[CuePrompt] Received from app:", event.data);
  };
}

function disconnect() {
  clearReconnectTimer();
  if (ws) {
    try {
      ws.send(JSON.stringify({ type: "disconnect" }));
    } catch (_) {}
    ws.close();
    ws = null;
  }
  connectionState = "disconnected";
  broadcastState();
}

function send(message) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(message));
    return true;
  }
  return false;
}

function scheduleReconnect() {
  clearReconnectTimer();
  reconnectTimer = setTimeout(() => connect(), 3000);
}

function clearReconnectTimer() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
}

function broadcastState() {
  chrome.runtime.sendMessage({
    type: "connectionState",
    state: connectionState,
  }).catch(() => {}); // popup may not be open
}

// Listen for messages from content scripts and popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case "getState":
      sendResponse({ state: connectionState });
      return true;

    case "connect":
      connect();
      sendResponse({ ok: true });
      return true;

    case "disconnect":
      disconnect();
      sendResponse({ ok: true });
      return true;

    case "fullSync":
    case "slideUpdate":
      const sent = send(message);
      sendResponse({ sent });
      return true;
  }
});

// Auto-connect on install/startup
connect();

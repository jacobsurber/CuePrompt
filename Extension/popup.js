// CuePrompt Companion — Popup UI logic

const dot = document.getElementById("dot");
const label = document.getElementById("label");
const btn = document.getElementById("btn");

const labels = {
  disconnected: "Disconnected",
  connecting: "Connecting...",
  connected: "Connected to CuePrompt",
};

function updateUI(state) {
  dot.className = "dot " + state;
  label.textContent = labels[state] || state;

  if (state === "connected") {
    btn.textContent = "Disconnect";
    btn.classList.remove("primary");
  } else {
    btn.textContent = "Connect";
    btn.classList.add("primary");
  }
}

// Get current state on popup open
chrome.runtime.sendMessage({ type: "getState" }, (response) => {
  if (response) updateUI(response.state);
});

// Listen for state changes
chrome.runtime.onMessage.addListener((message) => {
  if (message.type === "connectionState") {
    updateUI(message.state);
  }
});

// Toggle connection
btn.addEventListener("click", () => {
  chrome.runtime.sendMessage({ type: "getState" }, (response) => {
    if (response && response.state === "connected") {
      chrome.runtime.sendMessage({ type: "disconnect" });
    } else {
      chrome.runtime.sendMessage({ type: "connect" });
    }
  });
});

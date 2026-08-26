const HOST = "net.imput.helium_mpv";
const streamsElement = document.querySelector("#streams");
const streamLabelElement = document.querySelector("#stream-label");
const emptyElement = document.querySelector("#empty");
const playButton = document.querySelector("#play");
const statusElement = document.querySelector("#status");

let tab;
let streams = [];

function setStatus(message, error = false) {
  statusElement.textContent = message;
  statusElement.classList.toggle("error", error);
}

function formatStreamLabel(stream) {
  let host = stream.url;
  try {
    host = new URL(stream.url).host;
  } catch {}
  return `${stream.type} — ${host}`;
}

async function loadStreams() {
  [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  const key = `streams:${tab.id}`;
  streams = (await chrome.storage.session.get(key))[key] || [];

  emptyElement.hidden = streams.length > 0;
  streamLabelElement.hidden = streams.length === 0;
  streamsElement.hidden = streams.length === 0;
  playButton.disabled = streams.length === 0;

  for (const [index, stream] of streams.entries()) {
    const option = document.createElement("option");
    option.value = String(index);
    option.textContent = formatStreamLabel(stream);
    option.title = stream.url;
    streamsElement.append(option);
  }
}

playButton.addEventListener("click", () => {
  const stream = streams[Number(streamsElement.value)];
  if (!stream) return;

  playButton.disabled = true;
  setStatus("Opening mpv…");
  chrome.runtime.sendNativeMessage(
    HOST,
    { ...stream, title: tab.title || "Web stream" },
    async (response) => {
      if (chrome.runtime.lastError) {
        setStatus(chrome.runtime.lastError.message, true);
        playButton.disabled = false;
        return;
      }
      if (!response?.ok) {
        setStatus(response?.error || "Native host failed", true);
        playButton.disabled = false;
        return;
      }
      await chrome.tabs.update(tab.id, { muted: true });
      setStatus("Opened in mpv; browser tab muted.");
    }
  );
});

loadStreams().catch((error) => setStatus(error.message, true));

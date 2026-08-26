const pendingRequests = new Map();
const writes = new Map();
const requestTypes = { types: ["media", "other", "xmlhttprequest"] };

function streamType(url, contentType = "") {
  const path = url.toLowerCase();
  const mime = contentType.toLowerCase();
  if (/\.m3u8(?:$|[?#])/.test(path) || mime.includes("mpegurl")) return "HLS";
  if (/\.mpd(?:$|[?#])/.test(path) || mime.includes("dash+xml")) return "DASH";
  if (/\.flv(?:$|[?#])/.test(path) || mime.includes("video/x-flv")) return "FLV";
  return null;
}

function selectedHeaders(headers = []) {
  const selected = {};
  for (const { name, value = "" } of headers) {
    const normalized = name.toLowerCase();
    if (["authorization", "cookie", "origin", "referer", "user-agent"].includes(normalized)) {
      selected[normalized] = value;
    }
  }
  return selected;
}

function remember(details, type, headers = {}) {
  if (details.tabId < 0 || !/^https?:/.test(details.url)) return;

  const key = `streams:${details.tabId}`;
  const previous = writes.get(key) || Promise.resolve();
  const current = previous.then(async () => {
    const result = await chrome.storage.session.get(key);
    const streams = result[key] || [];
    const candidate = {
      url: details.url,
      type,
      headers,
      pageUrl: details.documentUrl || details.initiator || "",
      foundAt: Date.now()
    };
    const next = [candidate, ...streams.filter((stream) => stream.url !== candidate.url)].slice(0, 12);
    await chrome.storage.session.set({ [key]: next });
    await chrome.action.setBadgeBackgroundColor({ tabId: details.tabId, color: "#7aa2f7" });
    await chrome.action.setBadgeText({ tabId: details.tabId, text: String(next.length) });
  });

  const queued = current.finally(() => {
    if (writes.get(key) === queued) writes.delete(key);
  });
  writes.set(key, queued);
}

chrome.webRequest.onBeforeSendHeaders.addListener(
  (details) => {
    const headers = selectedHeaders(details.requestHeaders);
    pendingRequests.set(details.requestId, { details, headers });
    if (pendingRequests.size > 250) pendingRequests.delete(pendingRequests.keys().next().value);

    const type = streamType(details.url);
    if (type) remember(details, type, headers);
  },
  { urls: ["<all_urls>"], ...requestTypes },
  ["requestHeaders", "extraHeaders"]
);

chrome.webRequest.onHeadersReceived.addListener(
  (details) => {
    const contentType = details.responseHeaders?.find(
      (header) => header.name.toLowerCase() === "content-type"
    )?.value || "";
    const type = streamType(details.url, contentType);
    const pending = pendingRequests.get(details.requestId);
    if (type) remember(pending?.details || details, type, pending?.headers || {});
    pendingRequests.delete(details.requestId);
  },
  { urls: ["<all_urls>"], ...requestTypes },
  ["responseHeaders", "extraHeaders"]
);

function forgetRequest(details) {
  pendingRequests.delete(details.requestId);
}

chrome.webRequest.onCompleted.addListener(forgetRequest, { urls: ["<all_urls>"], ...requestTypes });
chrome.webRequest.onErrorOccurred.addListener(forgetRequest, { urls: ["<all_urls>"], ...requestTypes });

chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.status !== "loading") return;
  chrome.storage.session.remove(`streams:${tabId}`);
  chrome.action.setBadgeText({ tabId, text: "" });
});

chrome.tabs.onRemoved.addListener((tabId) => chrome.storage.session.remove(`streams:${tabId}`));

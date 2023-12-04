// This service worker is required to expose an exported Godot project as a
// Progressive Web App. It provides an offline fallback page telling the user
// that they need an Internet connection to run the project if desired.
// Incrementing CACHE_VERSION will kick off the install event and force
// previously cached resources to be updated from the network.
const CACHE_VERSION = "1701729771|14868110111";
const CACHE_PREFIX = "Godot-project-sw-cache-";
const CACHE_NAME = CACHE_PREFIX + CACHE_VERSION;
const OFFLINE_URL = "index.offline.html";

self.addEventListener("install", (event) => {
	event.waitUntil(
		caches.open(CACHE_NAME).then((cache) => cache.addAll(FULL_CACHE))
	);
});

self.addEventListener("activate", (event) => {
	event.waitUntil(
		caches.keys().then((keys) =>
			Promise.all(
				keys
					.filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME)
					.map((key) => caches.delete(key))
			)
		)
	);
});

async function fetchAndCache(event, cache) {
	let response = await event.preloadResponse;
	if (!response) {
		response = await self.fetch(event.request);
		cache.put(event.request, response.clone());
	}
	return response;
}

self.addEventListener("fetch", (event) => {
	event.respondWith(
		(async function () {
			const cache = await caches.open(CACHE_NAME);

			// Try to use cache first
			const cached = await cache.match(event.request);

			if (cached) {
				return cached;
			} else {
				// Try network if not in cache
				return fetchAndCache(event, cache);
			}
		})()
	);
});

self.addEventListener("message", (event) => {
	if (event.origin !== self.origin) {
		return;
	}
	const id = event.source.id || "";
	const msg = event.data || "";

	self.clients.get(id).then((client) => {
		if (!client) {
			return; // Not a valid client.
		}
		if (msg === "claim") {
			self.skipWaiting().then(() => self.clients.claim());
		} else if (msg === "clear") {
			caches.delete(CACHE_NAME);
		} else if (msg === "update") {
			self.skipWaiting()
				.then(() => self.clients.claim())
				.then(() => self.clients.matchAll())
				.then((all) =>
					all.forEach((c) => c.navigate(c.url).catch(() => { }))
				);
		} else {
			onClientMessage(event);
		}
	});
});

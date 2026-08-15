'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "4a0dc5b78e177d9e18762532d1fe4071",
"assets/AssetManifest.bin.json": "db56339623d5ed5b139dfce70a916a62",
"assets/AssetManifest.json": "b0a9355deacc4e7b7670d726ce789993",
"assets/assets/images/cards/color-card.jpg": "1d4b8b8f5a3cb347a40a1927bf6114db",
"assets/assets/images/cards/haircut-card.jpg": "cfe75ac4caa029e670bc6aa0b6a33c99",
"assets/assets/images/cards/treatment-card.jpg": "452c6fad9093721498c036366c1ee73d",
"assets/assets/images/colors/ash-brown.jpg": "5389b56368230a2b547aeedd5149f1c6",
"assets/assets/images/colors/balayage.jpg": "4f1e02051f611eea52ec0180a682c291",
"assets/assets/images/colors/blonde.jpg": "ec0728c49b8293836c75dbc78205836d",
"assets/assets/images/colors/burgundy.jpg": "d6a4ed6e036b3602e96cc3ca5ad31bc4",
"assets/assets/images/colors/jet-black.jpg": "aad50e665793f6d2d90402a0c456c3c8",
"assets/assets/images/colors/ombre.jpg": "b4e66c14a9888cca07418f4dd52afd09",
"assets/assets/images/colors/rose-gold.jpg": "6e6fd7f6f0b14b5e785b17112e1aabae",
"assets/assets/images/colors/silver.jpg": "6afe46527eb4ac59911f680a8927918a",
"assets/assets/images/colors/violet.jpg": "92bdcab5de4e5314015d7373e3f3ffbe",
"assets/assets/images/favicon.png": "2d5fe10a5311e3a5f6e684402697a041",
"assets/assets/images/haircuts/bob-cut.jpg": "43198bcef41687663738d14cf510d4bb",
"assets/assets/images/haircuts/crew-cut.jpg": "0c513e7e08cce649b838846dc04822d1",
"assets/assets/images/haircuts/curtain-bangs.jpg": "e5c6a32c1bcdd7eaaae69471a9c54318",
"assets/assets/images/haircuts/fade-cut.jpg": "9f0ba9dc7375400407258ce784b57555",
"assets/assets/images/haircuts/feather-cut.jpg": "1a82fd864a9ce52456f51897d158f764",
"assets/assets/images/haircuts/layered-cut.jpg": "2dd4cd5c45eed8b75a8602323b441763",
"assets/assets/images/haircuts/pompadour.jpg": "9413196e1754b11b30e6d71a1aeca75d",
"assets/assets/images/haircuts/taper-cut.jpg": "e5ce9d88687838b6a8f40d8915258a91",
"assets/assets/images/haircuts/undercut.jpg": "583016570aa70ae4e62e6d11a84b05a2",
"assets/assets/images/haircuts/wolf-cut.jpg": "a6da19cebed615400344dff92e2d4a61",
"assets/assets/images/treatments/brazilian-blowout.jpg": "e893a430b62ec91be95c9ef2649dad4d",
"assets/assets/images/treatments/color-protect.jpg": "e2e27bcca7296fdf1afae8ca1c4db713",
"assets/assets/images/treatments/hair-botox.jpg": "ff798800f8968c925cfdbcb7fb313379",
"assets/assets/images/treatments/hair-rebonding.jpg": "5d03cd5121b9786dc967fbae8c8370a4",
"assets/assets/images/treatments/hair-spa.jpg": "e59fb81b1ac2df2a930418d8cae0b154",
"assets/assets/images/treatments/hot-oil-treatment.jpg": "ab7ea6150e7f753f51e337907375114d",
"assets/assets/images/treatments/keratin-treatment.jpg": "22193c5fbc2f5c280826735af178f04b",
"assets/assets/images/treatments/scalp-detox.jpg": "b9853e9c8f98edb3dc5e1b38f939774a",
"assets/assets/images/treatments/smart-bond.jpg": "cc8200337bd6aca123e145b2f18d4d13",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/fonts/MaterialIcons-Regular.otf": "58455bc6d1a343e9a9b56fbd8f40f5e2",
"assets/NOTICES": "182bda044c7c62882b57208480021f7e",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "2d5fe10a5311e3a5f6e684402697a041",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "6d85a345c63877b5c99e49fbdbe423b4",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "681395b3fa79e05f1b785a7e19f70fb4",
"/": "681395b3fa79e05f1b785a7e19f70fb4",
"main.dart.js": "adcd6b02581b18a99fc88785a88d8a5d",
"manifest.json": "f922346575463577f64caba5756a6835",
"version.json": "23ba75600800dfd2f8d3488d16fded97"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

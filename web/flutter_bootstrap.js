{{flutter_js}}
{{flutter_build_config}}

// Niente impostazioni del service worker: quello di Flutter (dalla 3.2x)
// si disinstalla da solo e toglierebbe di mezzo quello di Pellovi (sw.js),
// che è registrato da index.html.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    const splash = document.getElementById('splash');
    if (splash) splash.remove();
    await appRunner.runApp();
  },
});

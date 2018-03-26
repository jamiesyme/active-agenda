// Any comment. You must start the file with a single-line comment!
pref("general.config.filename", "active-agenda.cfg");
pref("general.config.obscure_value", 0);

pref("toolkit.defaultChromeURI", "chrome://aaupdater/content/updater.xul");
pref("toolkit.defaultChromeFeatures", "chrome,resizable,centerscreen,dialog=no");
pref("extensions.activeagenda.server", 'https://xias.teracet.com:4439/');


//to show js/css errors in error console
pref("devtools.errorconsole.enabled", true);
pref("javascript.options.showInConsole", true);
pref("browser.dom.window.dump.enabled", true);
pref("javascript.options.strict", true);
pref("devtools.chrome.enabled", true);
pref("devtools.chrome.enabled", true);
pref("devtools.debugger.remote-enabled", true);
pref("devtools.debugger.prompt-connection", true);
pref("layout.css.report_errors", true);
pref("extensions.logging.enabled", true);
pref("dom.report_all_js_exceptions", true);
pref("devtools.errorconsole.deprecation_warnings", true);
pref("nglayout.debug.disable_xul_fastload", true);

pref("xpinstall.signatures.required", false);
pref("extensions.legacy.enabled", true);
pref("extensions.allow-non-mpc-extensions", true);

pref("nglayout.debug.disable_xul_cache", true);
pref("browser.preferences.instantApply", true);


// mozilla.cfg stuff
// Any comment. You must start the file with a comment!

// Disable updater
pref("app.update.enabled", false);
// make absolutely sure it is really off
pref("app.update.auto", false);
pref("app.update.mode", 0);
pref("app.update.service.enabled", false);

// Disable Add-ons compatibility checking
//clearPref("extensions.lastAppVersion"); 

// Don't show 'know your rights' on first run
pref("browser.rights.3.shown", true);

// Don't show WhatsNew on first run after every update
pref("browser.startup.homepage_override.mstone","ignore");

// Set default homepage - users can change
// Requires a complex preference
pref("browser.startup.homepage","data:text/plain,browser.startup.homepage=http://www.teracet.com");

// Disable the internal PDF viewer
pref("pdfjs.disabled", true);

// Disable the flash to javascript converter
pref("shumway.disabled", true);

// Don't ask to install the Flash plugin
pref("plugins.notifyMissingFlash", false);

//Disable plugin checking
pref("plugins.hide_infobar_for_outdated_plugin", true);
//clearPref("plugins.update.url");

// Disable health reporter
pref("datareporting.healthreport.service.enabled", false);

// Disable all data upload (Telemetry and FHR)
pref("datareporting.policy.dataSubmissionEnabled", false);

// Disable crash reporter
pref("toolkit.crashreporter.enabled", false);
//Components.classes["@mozilla.org/toolkit/crash-reporter;1"].getService(Components.interfaces.nsICrashReporter).submitReports = false; 


// Other stuff
pref("network.captive-portal-service.enabled", false);
pref("extensions.update.enabled", false);
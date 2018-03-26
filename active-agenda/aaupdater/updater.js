//
//	Establish server URL, extension path
//
Components.utils.import("resource://gre/modules/osfile.jsm");
Components.utils.import("resource://gre/modules/Http.jsm");
var prefManager = Components.classes["@mozilla.org/preferences-service;1"]
                    .getService(Components.interfaces.nsIPrefBranch);

var AAserver = prefManager.getCharPref('extensions.activeagenda.server');

//const aaVersionURL = AAserver + 'client/2.0/jars/aa.version';
const aaVersionURL = AAserver + 'client/3.0/jars/aa-version.json';
const aaJarURL = AAserver + 'client/3.0/jars/aa.jar';
const aaImagesJarURL = AAserver + 'client/3.0/jars/aa-images.jar';
const aaServerURL = AAserver + '/index.php';

const id = "aa@teracet.com";
const STATE_STOP = Components.interfaces.nsIWebProgressListener.STATE_STOP;
var _VERSION_LOCAL  = {};
var _VERSION_SERVER = {};
var _DOWNLOADING = false;
var _AA_JAR_EXISTS = false;
var _AA_IMAGES_JAR_EXISTS = false;
var _AA_VERSION_EXISTS = false;
var _UPDATE_TIMEOUT = null;

var _DOWNLOADS_ACTIVE = 0;
var _FILES_TO_CHECK = 3;
    
var goToOrgSetup = false;

// Path to Active Agenda Installation
var ext = Components.classes["@mozilla.org/file/directory_service;1"]
                     .getService(Components.interfaces.nsIProperties)
                     .get("CurProcD", Components.interfaces.nsIFile);
// NOTE: "file" is an object that implements nsIFile. If you want the
// file system path, use file.path

/*
var ext = Components.classes["@mozilla.org/extensions/manager;1"]
                    .getService(Components.interfaces.nsIExtensionManager)
                    .getInstallLocation(id)
                    .getItemLocation(id); 
*/



// This is true if session is already open, go skip login go directly to AA
// Checked when submitting version number
var openSession = false;

//	Directory path seperator, set based on platform
var dirSep = '/';
if (navigator.platform.toLowerCase().indexOf('win') > -1) {
	dirSep = '\\';
}

// ext is an instance of nsIFile, so ext.path contains the directory as a string
//var extPath = (navigator.platform.toLowerCase().indexOf('win') > -1) ? ext.path + '\\chrome\\' : ext.path + '/chrome/';
var extPath = ext.path + dirSep;
console.log("Install dir:" + extPath);

//
//  Add event listener to check if SHIFT is down when about to update, if so
//  force update. TODO: This doesn't work unless shift is pressed with the updater
//  window open.  Will need to use OS API to get key state to work with shift down before
//  app opens. See https://developer.mozilla.org/en-US/docs/Mozilla/js-ctypes/Using_js-ctypes/Standard_OS_Libraries
//

var _FORCE_UPDATE = false;
window.addEventListener("keydown", toggleForceUpdate, false);
function toggleForceUpdate(e){
    _FORCE_UPDATE = e.shiftKey; // Hold shift to force update
    console.log("force update: " + _FORCE_UPDATE);
}
function filesExistCheck(){
    // Check for update
	document.getElementById('retry-update').setAttribute('disabled', 'true');
    document.getElementById('start-aa').setAttribute('disabled', 'true');
    outputToUpdateConsole('Checking for Active Agenda update ...');
    
    OS.File.exists(extPath + 'aa.jar')
    .then(function(r){ 
        _AA_JAR_EXISTS = r;
        return OS.File.exists(extPath + 'aa-images.jar');
    })
    .then(function(r){ 
        _AA_IMAGES_JAR_EXISTS = r;
        return OS.File.exists(extPath + 'aa-version.json');
    })
    .then(function(r){ 
        _AA_VERSION_EXISTS = r;
        startAAupdate();
    });
}
function startAAupdate(){
    // if offline...
    if (navigator.onLine == false){
        
        if (_AA_JAR_EXISTS == true){
            outputToUpdateConsole("You are not connected to the internet, unable to check for an Active Agenda update.");
            outputToUpdateConsole("Click 'Continue' to use Active Agenda in offline mode.");
            document.getElementById('retry-update').setAttribute('disabled', 'false');
            document.getElementById('start-aa').setAttribute('disabled', 'false');
            return false;
        }
        else {
            outputToUpdateConsole("You are not connected to the internet, unable to check for an Active Agenda update.");
            outputToUpdateConsole("You must successfully update Active Agenda at least once before you can use offline mode.");
            return false;
        }
    }
    // Online and have all files, check version
    else if (_AA_VERSION_EXISTS === true && _AA_JAR_EXISTS === true && _AA_IMAGES_JAR_EXISTS == true){
        // Read local version JSON file
        if (!OS.File.exists(extPath + 'aa-version.json')){
            console.log('no aa-version.json,update');
            updateAA = true;
        }
        let decoder = new TextDecoder();
        var p = OS.File.read(extPath + 'aa-version.json');
        p = p.then(
            function onSuccess(array){
                try {
                    _VERSION_LOCAL = JSON.parse(decoder.decode(array));
                    
                    // Read server version JSON file
                    var xhr = new httpRequest(aaVersionURL, {
                        onLoad : function(data,meta){
                            try {
                                var _VERSION_SERVER = JSON.parse(data);

                                
                                // Analyze/compare local version with server version
                                var updateAA = (_VERSION_LOCAL.aaJar !== _VERSION_SERVER.aaJar);
                                var updateAAImgs = (_VERSION_LOCAL.aaImgsJar !== _VERSION_SERVER.aaImgsJar);
                                
                                if (updateAA || updateAAImgs){
                                    try {
                                        aaDownload(updateAA, updateAAImgs);
                                    } catch (e) {
                                        outputToUpdateConsole("Error updating :\n" + e);
                                        updateFailed();
                                        return false;
                                    }
                                }
                                else {
                                    outputToUpdateConsole('No update needed ...');
                                    updateSucceeded();
                                    return true;
                                }
                            }
                            catch(e){
                                console.log('error reading server version JSON.' + e);
                                updateFailed();
                            }
                        }
                        ,onError:function(){
                            console.log('http error');
                            updateFailed();
                        }
                    });
                }
                catch(e){
                    console.log("Error parsing aa-version.json");
                    _VERSION_LOCAL = true;
                }
        });
    }
    // Online and missing files, update
    else {
        
        outputToUpdateConsole('Please wait, updating ...');
        
        if (_AA_VERSION_EXISTS == false) {
            var aaJarNeeded = true;
            var aaImagesJarNeeded = true;
        }
        else {
            var aaJarNeeded = (_AA_JAR_EXISTS == true) ? false : true;
            var aaImagesJarNeeded = (_AA_IMAGES_JAR_EXISTS == true) ? false : true;
        }
        
        try {
            aaDownload(aaJarNeeded, aaImagesJarNeeded);
        } catch (e) {
            outputToUpdateConsole("Error updating :\n" + e);
            updateFailed();
            return;
        }
    }

	return false;
}
function updateSucceeded(btnClicked){
    //alert('success!');
    if (_DOWNLOADS_ACTIVE != 0)
        return false;
    
    // Clicked 'continue' to go in offline mode, setp pref
    if (btnClicked)
        prefManager.setBoolPref("extensions.activeagenda.workOffline", true);
    else {
        prefManager.setBoolPref("extensions.activeagenda.workOffline", false);
        outputToUpdateConsole('Update check complete');
    }
    
    //outputToUpdateConsole('GO TO APP!');outputToUpdateConsole('Update check complete');return false;

    // If running with -orgsetup go to orgsetup now
    if (goToOrgSetup == true)
        window.location = "chrome://aaorgsetup/content/main.xul";
    // Goto aa if logged in, else login screen
    else if (openSession == true){
        //window.location("chrome://aa/aa/main.xul", "Active Agenda", 
        //  "chrome,width=600,height=300");
        //window.location = "chrome://aa/aa/main.xul";
        window.location = "chrome://aa/content/main.xul";
    }
    else {
        //window.location("chrome://aalogin/login/main.xul", "Active Agenda", 
        //  "chrome,width=600,height=300");
        //window.location = "chrome://aalogin/login/main.xul";
        window.location = "chrome://aalogin/content/main.xul";
    }
}
function updateFailed(){
    outputToUpdateConsole("Error communicating with server, unable to check for an Active Agenda update.  Please verify your internet connection is functional.");
    if (goToOrgSetup == true){
        outputToUpdateConsole("Unable to start Organization Setup, an internet connection is required. ");
        document.getElementById('retry-update').setAttribute('disabled', 'true');
    }
    else if (_AA_JAR_EXISTS == true){
        outputToUpdateConsole("Click 'Continue' to use Active Agenda in offline mode.");
        document.getElementById('retry-update').setAttribute('disabled', 'false');
        document.getElementById('start-aa').setAttribute('disabled', 'false');
        return false;
    }
    else {
        outputToUpdateConsole("You must successfully update Active Agenda at least once before you can use offline mode.");
        document.getElementById('retry-update').setAttribute('disabled', 'false');
        return false;
    }
}

//
//	Downloads a file
//
function downloadFile(source_url, destFile){
	// convert string filepath to an nsIFile
   /*
  var file = Components.classes["@mozilla.org/file/local;1"]
                       .createInstance(Components.interfaces.nsILocalFile);
    file.initWithPath(destFile);
   */
    var FileUtils = Components.utils.import("resource://gre/modules/FileUtils.jsm").FileUtils;
    var file = new FileUtils.File(destFile);
    file.initWithPath( destFile );
  
  
  
  // create a data url from the canvas and then create URIs of the source and targets  
  var io = Components.classes["@mozilla.org/network/io-service;1"]
                     .getService(Components.interfaces.nsIIOService);
  //var source = io.newURI(canvas.toDataURL("image/png", ""), "UTF8", null);
  var source = io.newURI(source_url, "UTF8", null);
  var target = io.newFileURI(file);
  
  // prepare to save the canvas data
  var persist = Components.classes["@mozilla.org/embedding/browser/nsWebBrowserPersist;1"]
                          .createInstance(Components.interfaces.nsIWebBrowserPersist);
  
  persist.persistFlags = Components.interfaces.nsIWebBrowserPersist.PERSIST_FLAGS_REPLACE_EXISTING_FILES;
  persist.persistFlags |= Components.interfaces.nsIWebBrowserPersist.PERSIST_FLAGS_AUTODETECT_APPLY_CONVERSION;
  persist.persistFlags |= Components.interfaces.nsIWebBrowserPersist.PERSIST_FLAGS_BYPASS_CACHE;
  
  // displays a download dialog (remove these 3 lines for silent download)
  //var xfer = Components.classes["@mozilla.org/transfer;1"]
  //                     .createInstance(Components.interfaces.nsITransfer);
  //xfer.init(source, target, "", null, null, null, persist);
  persist.progressListener = xfer;
  
  // save the canvas data to the file
  //persist.saveURI(source, null, null, null, null, file);
  persist.saveURI(source, null, null, null, null, null, file,null);
}
//
//	Outputs to update console
//
function outputToUpdateConsole(txt){
	/*
    var l1 = document.createElement('label');
	l1.setAttribute('value', txt);
	document.getElementById('output_console').appendChild(l1);
    */
    var c = document.getElementById('console_txt');
    if (c.value != '')
        txt = "\n" + txt;
    document.getElementById('console_txt').value += txt;
    
    // Scroll to bottom
    //var TextBoxElement = <TextBoxElement>;
    var ti = document.getAnonymousNodes(c)[0].childNodes[0];
    ti.scrollTop=ti.scrollHeight;
    
}


//
//	Downloads and installs AA
//
function aaDownload(aaJarNeeded, aaImagesJarNeeded){
	_DOWNLOADING = true;
	
	// Download aa.version
	var dest1 = extPath + 'aa-version.json';
	downloadFile(aaVersionURL, dest1);
    
    // If downloading both
    
	
	// Download aa.jar if necessary
    if (aaJarNeeded == true){
        _DOWNLOADS_ACTIVE++;
        outputToUpdateConsole("Downloading " + aaJarURL + " ...");
        var dest2 = extPath + 'aa.jar';
        downloadFile(aaJarURL, dest2);
    }
    
    // Download aa-images.jar if necessary by setting flag to be d
    if (aaImagesJarNeeded == true){
        _DOWNLOADS_ACTIVE++;
        var dest2 = extPath + 'aa-images.jar';
        outputToUpdateConsole("Downloading " + aaImagesJarURL + " ...");
        downloadFile(aaImagesJarURL, dest2);
    }
}
//
//	Download listener so we know when it's done
//
var xfer = { 
	stateIsRequest:false,
	QueryInterface : function(aIID) {
		if (aIID.equals(Components.interfaces.nsIWebProgressListener) ||
			aIID.equals(Components.interfaces.nsISupportsWeakReference) ||
			aIID.equals(Components.interfaces.nsISupports))
				return this;
		throw Components.results.NS_NOINTERFACE;
	},
	onStateChange : function(aProgress,aRequest,aFlag,aStatus) {
		if(aFlag & STATE_STOP){
            if (aRequest == null)
                return null;
            
			aRequest.QueryInterface(Components.interfaces.nsIChannel);
			// Update version number
			if (aRequest.URI.spec == aaVersionURL){
				//outputToUpdateConsole('aa.version downloaded, aa.jar downloading ...');
				//document.location.reload(true);
			}
			// Downloaded aa.jar, refresh to go to login screen
			if (aRequest.URI.spec == aaJarURL){
                _DOWNLOADS_ACTIVE--;
                /*
                var aaJar = FileIO.open(extPath + dirSep + 'aa.jar');
                if (aaJar.exists() == false) {
                    updateFailed();
                }
                */
                if (!OS.File.exists(extPath + dirSep + 'aa.jar'))
                    updateFailed();
                else {
                    outputToUpdateConsole('Download complete : ' + aRequest.URI.spec);
                    //document.location.reload(true);
                    updateSucceeded();
                }
			}
            if (aRequest.URI.spec == aaImagesJarURL){
                _DOWNLOADS_ACTIVE--;
                
                /*
                var aaJar = FileIO.open(extPath + dirSep + 'aa-images.jar');
                if (aaJar.exists() == false) {
                    updateFailed();
                }
                */
                if (!OS.File.exists(extPath + dirSep + 'aa-images.jar'))
                    updateFailed();
                else {
                    outputToUpdateConsole('Download complete : ' + aRequest.URI.spec);
                    //document.location.reload(true);
                    updateSucceeded();
                }
			}
            // Download finish, decriment DL count

			//alert("Wait a moment!\n"+aRequest.URI.spec);
		}
		//return 0;
	},

	onLocationChange : function(aProgress,aRequest,aLocation) {
		return 0;
	},
	onProgressChange : function(a,b,c,d,e,f){
        document.getElementById('download-progress').value = parseInt((c / f) * 100) ;
        
        //outputToUpdateConsole(parseInt((c / f) * 100));
        /*outputToUpdateConsole(c);
        outputToUpdateConsole(d);
        outputToUpdateConsole(e);
        outputToUpdateConsole(f);
        */
    },
	onStatusChange : function(a,b,c,d){},
	onSecurityChange : function(a,b,c){},
	onLinkIconAvailable : function(a){} 
};

//
//	If aa.jar is downloaded, restart (reopen) so we can access it
//
function aaRestart(){
	window.open("chrome://aaupdater/content/updater.xul", "Active Agenda", 
	"chrome,width=600,height=300, resizable, dialog=no");
	window.close();
}
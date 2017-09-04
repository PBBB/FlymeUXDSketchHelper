// 用来加载 framework，以及一些调试信息，可以无视
var Fletch_FrameworkPath = Fletch_FrameworkPath || COScript.currentCOScript().env().scriptURL.path().stringByDeletingLastPathComponent();
var Fletch_Log = Fletch_Log || log;
(function() {
 var mocha = Mocha.sharedRuntime();
 var frameworkName = "Fletch";
 var directory = Fletch_FrameworkPath;
 if (mocha.valueForKey(frameworkName)) {
 Fletch_Log("😎 loadFramework: `" + frameworkName + "` already loaded.");
 return true;
 } else if ([mocha loadFrameworkWithName:frameworkName inDirectory:directory]) {
 Fletch_Log("✅ loadFramework: `" + frameworkName + "` success!");
 mocha.setValue_forKey_(true, frameworkName);
 return true;
 } else {
 Fletch_Log("❌ loadFramework: `" + frameworkName + "` failed!: " + directory + ". Please define Fletch_FrameworkPath if you're trying to @import in a custom plugin");
 return false;
 }
 })();

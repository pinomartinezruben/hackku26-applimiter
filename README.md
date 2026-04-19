# hackku26-applimiter
Project for HACKU 2026 will incoporate an integrated app for the Android OS phone that will allow user custimization to limit apps according to their liking, with the way to surpass certain restriction or limits via OTP sent to a phone number given by the user... the user is encouraged to add someone else's phone number to increase accountability

{edit made to readme to check if obsidian is connected to the gh repo remotely}
{another edit to ensure connection test}

## Personal Documentation
1:21 PM - It took me a while but i got the github set up with my local connecting to remote with obsidian also enacted to connection

2:10 PM - just wiped everything, starting fresh sigh..

2:53 PM - I basically got back to square one smh but i finally have everything working good ... i think ... i hope ... i pray

4:13 PM:
so i followed this video for setting up flutter and kotlin to work together:
[How To Use Kotlin Code In Flutter | Learn To Send & Receive Data Between Flutter And Kotlin Code](https://youtu.be/b6vwXxV0W4Q?si=8Y_u6OCl_VzSxDlu)
I went to the top search bar of VSCode and selected `Flutter: New Project`
![[Pasted image 20260418161347.png]]

I clicked on `Empty Application`
![[Pasted image 20260418161951.png]]

Click a directory (folder) I wanted my flutter in
	You may have noticed I blocked the directory names, that's because i don't know how security works and I don't know if I should hide the names of my storage.
![[Pasted image 20260418162523.png]]


--
2:36 AM - I recognize in an app like this, I would need to have the ability to track the usage of every app on the phone. Therefore I am inquiring about the information for how my app may do such. I found that it may be good to look into the implementation of checking how to have the permission for `PACKAGE_USAGE-STATS` as the dedicated package to see the statistics (in this case: time an app was actively used forefrontly by the user).

I've learned from this forum thread:
[How to check if "android.permission.PACKAGE_USAGE_STATS" permission is given? - Stack Overflow](https://stackoverflow.com/questions/28921136/how-to-check-if-android-permission-package-usage-stats-permission-is-given)
 
that this block of code:
 ```AndroidManifest.xml
 
// Source - https://stackoverflow.com/q/28921136
// Posted by android developer, modified by community. See post 'Timeline' for 
	// change history
// Retrieved 2026-04-19, License - CC BY-SA 3.0

<uses-permission
    android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions"/>
 ```
May be of help in getting permission when its placed inside our AndroidManifest.xml account inside
```
C:\Users\pinom\projects\hackku_applimiter\android\app\src\main\AndroidManifest.xml
```

or inside Android Studio:
![[Pasted image 20260419025138.png]]
 [RUBEN, EXPLAIN WHY]

Troubleshoot:
Though I ran into a weird error:![[Pasted image 20260419025550.png]]

Although replacing the first line to this:
```
<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
```
Fixed the error? [RUBEN, EXPLAIN WHY]

I added to MainActivity.kt:
``` MainActivity.kt
// imports needed for permissions checker  
import android.app.AppOpsManager // includes funcs: onResume(), evaluateUsageStatsPermission(), getSystemService  
import android.content.Context  
import android.os.Process  
import android.util.Log
```
Then...
``` MainActivity.kt
  
// implement function for permissions check  
override fun onResume() {  
    super.onResume()  
    evaluateUsageStatsPermission()  
}  
  
private fun evaluateUsageStatsPermission() {  
    val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager  
    val mode = appOps.unsafeCheckOpNoThrow(  
        AppOpsManager.OPSTR_GET_USAGE_STATS,  
        Process.myUid(),  
        packageName  
    )
    if (mode == AppOpsManager.MODE_ALLOWED) { 
        Log.d("UsageStatsCheck", "GRANTED: PACKAGE_USAGE_STATS is active")  
    }  
    else {  
        promptForUsageStats()  
    }  
}  
private fun promptForUsageStats() {  
    Log.d("UsageStatsCheck", "DENIED: promptForUsageStats() called.")  
}
```
 [RUBEN, EXPLAIN WHY]


## Layout
App design jargon yatta yatta

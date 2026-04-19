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

From this implementaiton, there is an implemented `DENIED` state where the permissions to track are not given, therefore if we ran flutter in terminal such as:

    `PS C:\Users\pinom\projects\hackku_applimiter> flutter run`
    
Then we can expect a result like this:
```
Resolving dependencies... 
Downloading packages... 
  matcher 0.12.18 (0.12.19 available)
  meta 1.17.0 (1.18.2 available)
  test_api 0.7.8 (0.7.11 available)
  vector_math 2.2.0 (2.3.0 available)
Got dependencies!
4 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Launching lib\main.dart on SM A256E in debug mode...
Running Gradle task 'assembleDebug'...                            100.5s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...          18.9s
D/FlutterJNI(25286): Beginning load of flutter...
D/FlutterJNI(25286): flutter (null) was loaded normally!
I/flutter (25286): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
D/FlutterRenderer(25286): Width is zero. 0,0
D/FlutterRenderer(25286): Width is zero. 0,0
D/FlutterJNI(25286): Sending viewport metrics to the engine.
D/FlutterJNI(25286): Sending viewport metrics to the engine.
D/FlutterJNI(25286): Sending viewport metrics to the engine.
D/FlutterJNI(25286): Sending viewport metrics to the engine.
I/BLASTBufferQueue(25286): [434facd SurfaceView[com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity]@0#1](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceView(25286): 70580941 finishedDrawing
D/VRI[MainActivity]@129202c(25286): Setup new sync=wmsSync-VRI[MainActivity]@129202c#1
I/VRI[MainActivity]@129202c(25286): Creating new active sync group VRI[MainActivity]@129202c#2
D/VRI[MainActivity]@129202c(25286): Draw frame after cancel
D/VRI[MainActivity]@129202c(25286): registerCallbacksForSync syncBuffer=false
D/SurfaceView(25286): 70580941 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 1080, 2340] surfaceSize = 1080x2340
I/SV[70580941 MainActivity](25286): uSP: rtp = Rect(0, 0 - 1080, 2340) rtsw = 1080 rtsh = 2340
I/SV[70580941 MainActivity](25286): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SV[70580941 MainActivity](25286): aOrMT: VRI[MainActivity]@129202c t = android.view.SurfaceControl$Transaction@d8ab4a8 fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:401
I/VRI[MainActivity]@129202c(25286): mWNT: t=0xb400007c826d00d0 mBlastBufferQueue=0xb400007c6270d6b0 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1863 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932
D/VRI[MainActivity]@129202c(25286): Received frameDrawingCallback syncResult=0 frameNum=1.
I/VRI[MainActivity]@129202c(25286): mWNT: t=0xb400007c826d9c90 mBlastBufferQueue=0xb400007c6270d6b0 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$12.onFrameDraw:15441 android.view.ThreadedRenderer$1.onFrameDraw:718 <bottom of call stack>
I/VRI[MainActivity]@129202c(25286): Setting up sync and frameCommitCallback
I/BLASTBufferQueue(25286): [VRI[MainActivity]@129202c#0](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/VRI[MainActivity]@129202c(25286): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
D/HWUI    (25286): CFMS:: SetUp Pid : 25286    Tid : 25332
D/VRI[MainActivity]@129202c(25286): reportDrawFinished seqId=0
D/VRI[MainActivity]@129202c(25286): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb400007c42732490}
D/InputMethodManagerUtils(25286): startInputInner - Id : 0
I/InputMethodManager(25286): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager(25286): handleMessage: setImeVisibility visible=false
D/InsetsController(25286): hide(ime(), fromIme=false)
I/ImeTracker(25286): com.example.hackku_applimiter:f82fef6f: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport(25286): Input channel constructed: 'ClientS', fd=176
Syncing files to device SM A256E...                                228ms

d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on SM A256E is available at: http://127.0.0.1:59769/6IANv377Vbk=/
The Flutter DevTools debugger and profiler on SM A256E is available at: http://127.0.0.1:59769/6IANv377Vbk=/devtools/?uri=ws://127.0.0.1:59769/6IANv377Vbk=/ws
D/ProfileInstaller(25286): Installing profile for com.example.hackku_applimiter
W/ckku_applimiter(25286): userfaultfd: MOVE ioctl seems unsupported: Connection timed out
```

While this wall of text is large and difficult to read, there should have been a line like that below:

    `D/UsageStatsCheck(25286): DENIED: promptForUsageStats() called.
    
However, there wasn't.. and to be honest i dont know why it did not show, my guess is that because there was a connection timeout on the last line that it may have been something to do with it, but that is an uneducated guess.

So after terminal stayed with the most recent logging, I manually exited the app (without closing it), went to settings, and navigated to "Usage Data Access" on my Samsung phone. There I scrolled through the list of apps with a given toggle option, manually toggling my app to have Usage data access. Once I went back to VSCode on my laptop, i saw the following terminal output logs:

```
I/ImeFocusController(25286): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(25286): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
D/InputTransport(25286): Input channel destroyed: 'ClientS', fd=176
I/VRI[MainActivity]@129202c(25286): stopped(true) old = false
D/VRI[MainActivity]@129202c(25286): WindowStopped on com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity set to true
D/HWUI    (25286): CacheManager::trimMemory(20)
D/SurfaceView(25286): 253429578 windowPositionLost, frameNr = 0
I/SV[70580941 MainActivity](25286): aOrMT: VRI[MainActivity]@129202c t = android.view.SurfaceControl$Transaction@7f6d6bb fN = 0 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionLost:2025 android.graphics.RenderNode$CompositePositionUpdateListener.positionLost:418
I/VRI[MainActivity]@129202c(25286): mWNT: t=0xb400007c826e57d0 mBlastBufferQueue=0xb400007c6270d6b0 fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1863 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionLost:2025
I/SV[70580941 MainActivity](25286): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{434facd V.E...... ........ 0,0-1080,2340} of VRI[MainActivity]@129202c
I/SurfaceView(25286): 70580941 Changes: creating=false format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView(25286): 70580941 Cur surface: Surface(name=null mNativeObject=-5476376613191744416)/@0xd137db7
D/SurfaceComposerClient(25286): setCornerRadius ## 434facd SurfaceView[com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity]@0#91105 cornerRadius=0.000000
I/SurfaceView(25286): 70580941 surfaceDestroyed
I/SV[70580941 MainActivity](25286): surfaceDestroyed callback.size 1 #1 io.flutter.embedding.android.FlutterSurfaceView{434facd V.E...... ........ 0,0-1080,2340}
I/SV[70580941 MainActivity](25286): updateSurface: mVisible = false mSurface.isValid() = true
I/SV[70580941 MainActivity](25286): releaseSurfaces: viewRoot = VRI[MainActivity]@129202c
V/SurfaceView(25286): Layout: x=0 y=0 w=1080 h=2340, frame=Rect(0, 0 - 1080, 2340)
D/SV[70580941 MainActivity](25286): updateSurface: surface is not valid
I/SV[70580941 MainActivity](25286): releaseSurfaces: viewRoot = VRI[MainActivity]@129202c
I/VRI[MainActivity]@129202c(25286): handleAppVisibility mAppVisible = true visible = false
I/SV[70580941 MainActivity](25286): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{434facd G.E...... ......I. 0,0-1080,2340} of VRI[MainActivity]@129202c
D/SV[70580941 MainActivity](25286): updateSurface: surface is not valid
I/SV[70580941 MainActivity](25286): releaseSurfaces: viewRoot = VRI[MainActivity]@129202c
D/HWUI    (25286): CacheManager::trimMemory(20)
I/VRI[MainActivity]@129202c(25286): Relayout returned: old=(0,0,1080,2340) new=(0,0,1080,2340) relayoutAsync=false req=(1080,2340)8 dur=14 res=0x2 s={false 0x0} ch=false seqId=0
D/SV[70580941 MainActivity](25286): updateSurface: surface is not valid
I/SV[70580941 MainActivity](25286): releaseSurfaces: viewRoot = VRI[MainActivity]@129202c
D/VRI[MainActivity]@129202c(25286): applyTransactionOnDraw applyImmediately
D/VRI[MainActivity]@129202c(25286): Not drawing due to not visible. Reason=!mAppVisible && !mForceDecorViewVisibility
D/VRI[MainActivity]@129202c(25286): Pending transaction will not be applied in sync with a draw due to view not visible
I/VRI[MainActivity]@129202c(25286): mWNT: t=0xb400007c826c8f10 mBlastBufferQueue=0xnull fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl.handleSyncRequestWhenNoAsyncDraw:6733 android.view.ViewRootImpl.performTraversals:5504 android.view.ViewRootImpl.doTraversal:3924
D/HWUI    (25286): CacheManager::trimMemory(20)
D/BBA2    (25286): setIsFg isFg = false; delayValue 3999ms
D/Choreographer(25286): BBA2 receive callback when in bg : 4
D/HWUI    (25286): CacheManager::trimMemory(40)
I/VRI[MainActivity]@129202c(25286): handleAppVisibility mAppVisible = false visible = true
I/VRI[MainActivity]@129202c(25286): stopped(false) old = true
D/VRI[MainActivity]@129202c(25286): WindowStopped on com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity set to false
D/SV[70580941 MainActivity](25286): updateSurface: surface is not valid
I/SV[70580941 MainActivity](25286): releaseSurfaces: viewRoot = VRI[MainActivity]@129202c
D/VRI[MainActivity]@129202c(25286): applyTransactionOnDraw applyImmediately
D/UsageStatsCheck(25286): GRANTED: PACKAGE_USAGE_STATS is active
I/SV[70580941 MainActivity](25286): onWindowVisibilityChanged(0) false io.flutter.embedding.android.FlutterSurfaceView{434facd V.E...... ......ID 0,0-1080,2340} of VRI[MainActivity]@129202c
D/SV[70580941 MainActivity](25286): updateSurface: surface is not valid
I/SV[70580941 MainActivity](25286): releaseSurfaces: viewRoot = VRI[MainActivity]@129202c
D/VRI[MainActivity]@129202c(25286): applyTransactionOnDraw applyImmediately
I/BLASTBufferQueue_Java(25286): new BLASTBufferQueue, mName= VRI[MainActivity]@129202c mNativeObject= 0xb400007c626d9370 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3585 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910 android.view.Choreographer.doCallbacks:1367 android.view.Choreographer.doFrame:1292 android.view.Choreographer$FrameDisplayEventReceiver.run:1870
I/BLASTBufferQueue_Java(25286): update, w= 1080 h= 2340 mName = VRI[MainActivity]@129202c mNativeObject= 0xb400007c626d9370 sc.mNativeObject= 0xb400007cb26b8b10 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3590 android.view.ViewRootImpl.relayoutWindow:11685 android.view.ViewRootImpl.performTraversals:4804 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901
I/VRI[MainActivity]@129202c(25286): Relayout returned: old=(0,0,1080,2340) new=(0,0,1080,2340) relayoutAsync=false req=(1080,2340)0 dur=18 res=0x3 s={true 0xb400007c42771db0} ch=true seqId=0
D/VRI[MainActivity]@129202c(25286): mThreadedRenderer.initialize() mSurface={isValid=true 0xb400007c42771db0} hwInitialized=true     
I/SV[70580941 MainActivity](25286): windowStopped(false) true io.flutter.embedding.android.FlutterSurfaceView{434facd V.E...... ......ID 0,0-1080,2340} of VRI[MainActivity]@129202c
I/SurfaceView(25286): 70580941 Changes: creating=true format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/BLASTBufferQueue_Java(25286): new BLASTBufferQueue, mName= 434facd SurfaceView[com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity]@0 mNativeObject= 0xb400007c626ff5d0 caller= android.view.SurfaceView.createBlastSurfaceControls:1781 android.view.SurfaceView.updateSurface:1450 android.view.SurfaceView.setWindowStopped:539 android.view.SurfaceView.surfaceCreated:2327 android.view.ViewRootImpl.notifySurfaceCreated:3502 android.view.ViewRootImpl.performTraversals:5286 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910
I/BLASTBufferQueue_Java(25286): update, w= 1080 h= 2340 mName = 434facd SurfaceView[com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity]@0 mNativeObject= 0xb400007c626ff5d0 sc.mNativeObject= 0xb400007cb26c39d0 format= 4 caller= android.view.SurfaceView.createBlastSurfaceControls:1782 android.view.SurfaceView.updateSurface:1450 android.view.SurfaceView.setWindowStopped:539 android.view.SurfaceView.surfaceCreated:2327 android.view.ViewRootImpl.notifySurfaceCreated:3502 android.view.ViewRootImpl.performTraversals:5286
I/SurfaceView(25286): 70580941 Cur surface: Surface(name=null mNativeObject=0)/@0xd137db7
D/SurfaceComposerClient(25286): setCornerRadius ## 434facd SurfaceView[com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity]@0#91490 cornerRadius=0.000000
I/SV[70580941 MainActivity](25286): pST: sr = Rect(0, 0 - 1080, 2340) sw = 1080 sh = 2340
D/SurfaceView(25286): 70580941 performSurfaceTransaction RenderWorker position = [0, 0, 1080, 2340] surfaceSize = 1080x2340
I/SV[70580941 MainActivity](25286): updateSurface: mVisible = true mSurface.isValid() = true
I/SV[70580941 MainActivity](25286): updateSurface: mSurfaceCreated = false surfaceChanged = true visibleChanged = true
I/SurfaceView(25286): 70580941 visibleChanged -- surfaceCreated
I/SV[70580941 MainActivity](25286): surfaceCreated 1 #1 io.flutter.embedding.android.FlutterSurfaceView{434facd V.E...... ......ID 0,0-1080,2340}
E/gralloc4(25286): ERROR: Format allocation info not found for format: 38
E/gralloc4(25286): ERROR: Format allocation info not found for format: 0
E/gralloc4(25286): Invalid base format! req_base_format = 0x0, req_format = 0x38, type = 0x0
E/gralloc4(25286): ERROR: Unrecognized and/or unsupported format 0x38 and usage 0xb00
E/Gralloc4(25286): isSupported(1, 1, 56, 1, ...) failed with 5
E/GraphicBufferAllocator(25286): Failed to allocate (4 x 4) layerCount 1 format 56 usage b00: 5
E/AHardwareBuffer(25286): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/gralloc4(25286): ERROR: Format allocation info not found for format: 3b
E/gralloc4(25286): ERROR: Format allocation info not found for format: 0
E/gralloc4(25286): Invalid base format! req_base_format = 0x0, req_format = 0x3b, type = 0x0
E/gralloc4(25286): ERROR: Unrecognized and/or unsupported format 0x3b and usage 0xb00
E/Gralloc4(25286): isSupported(1, 1, 59, 1, ...) failed with 5
E/GraphicBufferAllocator(25286): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 5
E/AHardwareBuffer(25286): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/gralloc4(25286): ERROR: Format allocation info not found for format: 38
E/gralloc4(25286): ERROR: Format allocation info not found for format: 0
E/gralloc4(25286): Invalid base format! req_base_format = 0x0, req_format = 0x38, type = 0x0
E/gralloc4(25286): ERROR: Unrecognized and/or unsupported format 0x38 and usage 0xb00
E/Gralloc4(25286): isSupported(1, 1, 56, 1, ...) failed with 5
E/GraphicBufferAllocator(25286): Failed to allocate (4 x 4) layerCount 1 format 56 usage b00: 5
E/AHardwareBuffer(25286): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
E/gralloc4(25286): ERROR: Format allocation info not found for format: 3b
E/gralloc4(25286): ERROR: Format allocation info not found for format: 0
E/gralloc4(25286): Invalid base format! req_base_format = 0x0, req_format = 0x3b, type = 0x0
E/gralloc4(25286): ERROR: Unrecognized and/or unsupported format 0x3b and usage 0xb00
E/Gralloc4(25286): isSupported(1, 1, 59, 1, ...) failed with 5
E/GraphicBufferAllocator(25286): Failed to allocate (4 x 4) layerCount 1 format 59 usage b00: 5
E/AHardwareBuffer(25286): GraphicBuffer(w=4, h=4, lc=1) failed (Unknown error -5), handle=0x0
I/SurfaceView(25286): 70580941 surfaceChanged -- format=4 w=1080 h=2340
I/SV[70580941 MainActivity](25286): surfaceChanged (1080,2340) 1 #1 io.flutter.embedding.android.FlutterSurfaceView{434facd V.E...... ......ID 0,0-1080,2340}
I/SurfaceView(25286): 70580941 surfaceRedrawNeeded
V/SurfaceView(25286): Layout: x=0 y=0 w=1080 h=2340, frame=Rect(0, 0 - 1080, 2340)
D/VRI[MainActivity]@129202c(25286): reportNextDraw android.view.ViewRootImpl.performTraversals:5443 android.view.ViewRootImpl.doTraversal:3924 android.view.ViewRootImpl$TraversalRunnable.run:12903 android.view.Choreographer$CallbackRecord.run:1901 android.view.Choreographer$CallbackRecord.run:1910
D/VRI[MainActivity]@129202c(25286): Setup new sync=wmsSync-VRI[MainActivity]@129202c#4
I/VRI[MainActivity]@129202c(25286): Creating new active sync group VRI[MainActivity]@129202c#5
D/VRI[MainActivity]@129202c(25286): Start draw after previous draw not visible
D/VRI[MainActivity]@129202c(25286): registerCallbacksForSync syncBuffer=false
D/SurfaceView(25286): 70580941 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 1080, 2340] surfaceSize = 1080x2340
I/SV[70580941 MainActivity](25286): uSP: rtp = Rect(0, 0 - 1080, 2340) rtsw = 1080 rtsh = 2340
I/SV[70580941 MainActivity](25286): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SV[70580941 MainActivity](25286): aOrMT: VRI[MainActivity]@129202c t = android.view.SurfaceControl$Transaction@d6b6233 fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:401
I/VRI[MainActivity]@129202c(25286): mWNT: t=0xb400007c826ed5d0 mBlastBufferQueue=0xb400007c626d9370 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1863 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932
D/VRI[MainActivity]@129202c(25286): Received frameDrawingCallback syncResult=0 frameNum=1.
I/VRI[MainActivity]@129202c(25286): mWNT: t=0xb400007c826ee750 mBlastBufferQueue=0xb400007c626d9370 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$12.onFrameDraw:15441 android.view.ThreadedRenderer$1.onFrameDraw:718 <bottom of call stack>
I/VRI[MainActivity]@129202c(25286): Setting up sync and frameCommitCallback
I/BLASTBufferQueue(25286): [VRI[MainActivity]@129202c#2](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/VRI[MainActivity]@129202c(25286): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
I/InsetsSourceConsumer(25286): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity
I/InsetsSourceConsumer(25286): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity
I/BLASTBufferQueue(25286): [434facd SurfaceView[com.example.hackku_applimiter/com.example.hackku_applimiter.MainActivity]@0#3](f:0,a:0,s:0) onFrameAvailable the first frame is available
D/VRI[MainActivity]@129202c(25286): reportDrawFinished seqId=0
I/SurfaceView(25286): 70580941 finishedDrawing
D/VRI[MainActivity]@129202c(25286): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb400007c42771db0}
D/InputMethodManagerUtils(25286): startInputInner - Id : 0
I/InputMethodManager(25286): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager(25286): handleMessage: setImeVisibility visible=false
D/InsetsController(25286): hide(ime(), fromIme=false)
I/ImeTracker(25286): com.example.hackku_applimiter:bab71a62: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport(25286): Input channel constructed: 'ClientS', fd=178
```

Again, wall of text and a bit overwhelming to read, but we actually see the line:

    `D/UsageStatsCheck(25286): GRANTED: PACKAGE_USAGE_STATS is active`

This meant our native Kotlin code did connect with our Android OS system in our intended manner. The `AppOpsManager` in our `MainActivity.kt` sucessfully recognized that we manually fliped the switch in system settings and allowed the app to proceed.

## Layout
App design jargon yatta yatta

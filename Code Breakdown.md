In this project I only edited a handful of files thanks to flutter extension in VSCode allowing a prebuilt template app that I can build on top of. 

So the files I edited are the following:

```
hackku_applimiter/
├─ lib/
│  ├─ main.dart
│  ├─ main_page.dart
│  ├─ new_limiter_page.dart
│  ├─ limiter_list_page.dart
│  ├─ more_options.dart
├─ android/
   ├─ app/
      ├─ src/
         ├─ main/
         |  ├─ kotlin/
         |     ├─ example/
         |        ├─ hackku_applimiter/
         |           ├─ MainActivity.kt
         |           ├─ BlockActivity.kt
         |           ├─ limiter_service.kt
         |
         ├─ profile/
            ├─ AndroidManifest.xml
```

*NOTE: The project root directory that I am working on is not limited to the directories/files shown above. This just means that there are some directories that came with* `android/` that I did not display here because I did not edit any files in there.

In this document, I'd like to show through every chunk of code and what they are in there for.

Lets take a look at all of `main.dart`:

```dart
// import all the packages fot the materials needed for flutter development
import 'package:flutter/material.dart';
// main_page is the home page of our application, so we start the app there
import 'package:hackku_applimiter/main_page.dart';

// main function starts the app
void main() {
  //
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: true,
      home: MainPage(),
    );
  }
}
```
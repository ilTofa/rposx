Introduction
------------

[Radio Paradise](http://www.radioparadise.com) is a unique blend of many styles and genres of music, carefully selected and mixed by two real human beings — enhanced by a dazzling photo slideshow, tied in thematically with the songs that are playing. There's nothing else that's quite like it.

The Application
---------------

This is an OS X client for Radio Paradise. It is derived from the [iOS app](https://github.com/ilTofa/rp20) for radio paradise (also open source).

The app is currently published on the [Mac App Store](https://itunes.apple.com/app/id663334697). If you only ned the executable, grab it from there.

The code
--------

The code is almost the same of the iOS version and is based on AVPlayer, that manage all the audio play (both "standard" and PSD).

Main Controller
---------------

The main controller is RPWindowController. Code is hopefully easy to follow. There are 3 AVPlayer objects to manage the main stream and the PSD stream (PSD needs two object to manage the "PSD to PSD transition"), state transitions for the streams are managed via KVO.

Metadata about the played song are taken directly from radio paradise (not from the stream metadata, because AVPlayer do not supports that for network streams), a NSTimer handles the task (in -[metatadaHandler:timer]). Another NSTimer manages the load of the images for the HD stream (in -[loadNewImage:timer]). PSD play is triggered and managed here. The "return" from the PSD is also timer-triggered.

The management of UI state and stream start is via KVO.

The main controllers also tries to manage the fading between the main stream and the PSD streams. Unfortunately volume controls (and therefore the fading) don't work on main stream. This is a know limitation of AVPlayer (cfr. [Apple's qa1716](http://developer.apple.com/library/ios/#qa/qa1716/_index.html) ). The fading work on the PSD songs.

The application logs heavily when DLog() (defined in RadioParadise-Prefix.pch) is set to have output. Be aware to not distribute the application with logging on (it's really, really verbose).

Acknowledgements
----------------

This application uses code from:

[STKeyChain](https://github.com/ldandersen/STUtils/blob/master/Security/STKeychain.m) by Buzz Andersen
[PiwikTracker](https://github.com/mattiaslevin/PiwikTracker) by Mattias Levin
[iRate](https://github.com/nicklockwood/iRate) by Nick Lockwood.

The latest are included as submodules from my forks.
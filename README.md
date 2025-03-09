A tiny program to switch layout with Caps Lock on Windows.

It's very bare bones, no options, no anything. It just intercepts keypresses and if it detects Caps Lock pressed it sends Alt+Shift instead. Shift+CapsLock sends Caps Lock.

I just did it because similar tools I've tried before has a tendency to stop working under a heavy load so you have to restart them.
In theory I didn't do anything much different but somehow it works better for me. It sometimes misses keypresses when PC is stressed but it quickly recovers so haven't had to restart it yet even once.

I also wanted to try coding something in Zig so this was my first attempt - small enough for first time experience, yet useful enough for me to get it actually done.

It's written in Zig 0.13 and it's shipped with zigwin32 library snapshot so it should build fine with that. Zig is unstable so future versions might not work.
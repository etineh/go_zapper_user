
```bash
flutter clean
flutter pub get
```

```bash
flutter clean
flutter pub cache repair
rm -rf ~/.pub-cache/hosted/pub.dev/geolocator_android*
flutter pub get
```

```bash
rm -rf ios/Pods ios/Podfile.lock
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

#push to github. Prompt me a message to enter, then prompt a branch to push
```bash
./gitpush.sh
```

```bash
flutter build apk --release
```
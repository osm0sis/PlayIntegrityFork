## Custom Fork v15

- Improve autopif2 to support latest Pixel Beta changes, create TS security_patch.txt, fix false matches, use curl if present
- Fix PIF and Dobby detections, allow skipping persist props
- Add experimental spoofVendingFinger feature
- Fix migrate check on clean install
- Update Action to only force Strong setup if no config, improve behavior on WKSU
- Add prop config format support as default
- Rename example.app_replace.list to app_replace_list.txt

## Custom Fork v14

- Add cleaning modified persist props on uninstall
- Add opt-out props/detection for more PIH variants
- Fix spoofSignature crash with AGP 8.9+
- Add experimental spoofVendingSdk to Advanced
- Update Action and install migrate to add Advanced
- Update Action to match device on Pixels, set Strong since Pixel Beta no longer pass Device
- Improve ROM overlay xml support
- Add TS security_patch.txt Simple format support

_[Full changelogs](https://github.com/osm0sis/PlayIntegrityFork/releases)_

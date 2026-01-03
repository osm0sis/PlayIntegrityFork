## Custom Fork v16

- Add opt-out props/detection for latest PixelPropsUtils version
- Correct autopif2 version to autopif3 for Pixel Beta zip metadata method
- Improve autopif3 with preliminary TEESimulator security_patch.txt format support
- Add support for Magisk's file/directory whiteout implementation
- Update to autopif4 to generate prints using monthly Pixel Canary build info

## Custom Fork v15

- Improve autopif2 to support latest Pixel Beta changes, create TS security_patch.txt, fix false matches, use curl if present
- Fix PIF and Dobby detections, allow skipping persist props
- Add experimental spoofVendingFinger feature
- Fix migrate check on clean install
- Update Action to only force Strong setup if no config, improve behavior on WKSU
- Add prop config format support as default
- Rename example.app_replace.list to app_replace_list.txt

_[Full changelogs](https://github.com/osm0sis/PlayIntegrityFork/releases)_

function getprop(key) {
  return Shell.cmd(`getprop ${key}`).result();
}

export default {
  MANUFACTURER: getprop("ro.product.manufacturer"),
  MODEL: getprop("ro.product.model"),
  BRAND: getprop("ro.product.brand"),
  PRODUCT: getprop("ro.product.name"),
  DEVICE: getprop("ro.product.device"),
  RELEASE: getprop("ro.build.version.release"),
  ID: getprop("ro.build.id"),
  INCREMENTAL: getprop("ro.build.version.incremental"),
  TYPE: getprop("ro.build.type"),
  TAGS: getprop("ro.build.tags"),
  FINGERPRINT: getprop("ro.build.fingerprint"),
  SECURITY_PATCH: getprop("ro.build.version.security_patch"),
  DEVICE_INITIAL_SDK_INT: getprop("ro.product.first_api_level"),
  "*.build.id": getprop("ro.build.id"),
  "*.security_patch": getprop("ro.build.version.security_patch"),
  "*api_level": getprop("ro.build.version.sdk"),
};

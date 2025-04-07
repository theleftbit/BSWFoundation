
/// Bundle.module is not available on Android
/// unit tests, so for now we are turning these off
var isAndroid: Bool {
    #if os(Android)
    return true
    #else
    return false
    #endif
}

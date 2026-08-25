//
//  Browser support for WebAssembly hosts.
//

#if os(WASI)
import JavaScriptEventLoop

/// Browser-hosted WebAssembly setup helpers.
public enum BSWBrowserRuntime {

    nonisolated(unsafe) private static var didInstallJavaScriptEventLoop = false

    static var isJavaScriptEventLoopInstalled: Bool {
        didInstallJavaScriptEventLoop
    }

    /// Installs JavaScriptKit's event-loop executor.
    ///
    /// Browser WebAssembly applications must call this once at startup before creating
    /// ``APIClient`` or spawning async work.
    public static func installJavaScriptEventLoop() {
        JavaScriptEventLoop.installGlobalExecutor()
        didInstallJavaScriptEventLoop = true
    }
}
#endif

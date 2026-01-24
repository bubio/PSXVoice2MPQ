import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Set minimum window size
    self.minSize = NSSize(width: 500, height: 600)

    // Set initial window size
    let initialSize = NSSize(width: 600, height: 700)
    self.setContentSize(initialSize)

    // Center the window
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

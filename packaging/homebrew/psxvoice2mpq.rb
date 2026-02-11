# Homebrew Cask formula for PSXVoice2MPQ
#
# To use this formula, create a tap repository (e.g., homebrew-psxvoice2mpq)
# and place this file in the Casks/ directory.
#
# Users can then install with:
#   brew tap bubio/psxvoice2mpq
#   brew install --cask psxvoice2mpq
#
# Or directly:
#   brew install --cask bubio/psxvoice2mpq/psxvoice2mpq

cask "psxvoice2mpq" do
  version "1.0.0"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"

  url "https://github.com/bubio/PSXVoice2MPQ/releases/download/v#{version}/PSXVoice2MPQ-macOS.dmg"
  name "PSXVoice2MPQ"
  desc "Convert PlayStation 1 voice files to MPQ format for Diablo mods"
  homepage "https://github.com/bubio/PSXVoice2MPQ"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "PSXVoice2MPQ.app"

  zap trash: [
    "~/Library/Application Support/com.github.bubio.PSXVoice2MPQ",
    "~/Library/Preferences/com.github.bubio.PSXVoice2MPQ.plist",
    "~/Library/Caches/com.github.bubio.PSXVoice2MPQ",
  ]
end

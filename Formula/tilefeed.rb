class Tilefeed < Formula
  desc "PostGIS vector tile pipeline with incremental MBTiles updates via LISTEN/NOTIFY"
  homepage "https://github.com/muimsd/tilefeed"
  version "0.4.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/muimsd/tilefeed/releases/download/v0.4.0/tilefeed-aarch64-apple-darwin.tar.gz"
      sha256 "b927037a31787d2f26fb43920be15ca6717a9c0d516e6f5040fea3d354441f6b"
    end
    on_intel do
      url "https://github.com/muimsd/tilefeed/releases/download/v0.4.0/tilefeed-x86_64-apple-darwin.tar.gz"
      sha256 "ffe74da36d64371d8590a9ccdd8d79a2668ae5066ed0b18add6e14c0fe7a1c76"
    end
  end

  on_linux do
    url "https://github.com/muimsd/tilefeed/releases/download/v0.4.0/tilefeed-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "58d192f299f96fc5d89ee12428e9c1156ae355a5b0c59fd9c1578c78770f5316"
  end

  def install
    bin.install "tilefeed"
  end

  test do
    assert_match "tilefeed", shell_output("\#{bin}/tilefeed --help")
  end
end

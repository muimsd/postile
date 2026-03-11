class Tilefeed < Formula
  desc "PostGIS vector tile pipeline with incremental MBTiles updates via LISTEN/NOTIFY"
  homepage "https://github.com/muimsd/tilefeed"
  version "0.6.1"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/muimsd/tilefeed/releases/download/v0.6.1/tilefeed-aarch64-apple-darwin.tar.gz"
      sha256 "6b3c185ce3d55d2917d2ffc7451b4e2ea701766cbdb7c41400b4a45757be5885"
    end
    on_intel do
      url "https://github.com/muimsd/tilefeed/releases/download/v0.6.1/tilefeed-x86_64-apple-darwin.tar.gz"
      sha256 "9ecb670d3f18b70424c68022e48a7c29168d22ffd66d2df4fd797212ebb4e3bc"
    end
  end

  on_linux do
    url "https://github.com/muimsd/tilefeed/releases/download/v0.6.1/tilefeed-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "19b1d34b07f06066b8463005f0ff678551809e093c30a79dae7fd4c406858b8e"
  end

  def install
    bin.install "tilefeed"
  end

  test do
    assert_match "tilefeed", shell_output("\#{bin}/tilefeed --help")
  end
end

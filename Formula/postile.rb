class Postile < Formula
  desc "PostGIS vector tile pipeline with incremental MBTiles updates via LISTEN/NOTIFY"
  homepage "https://github.com/muimsd/postile"
  version "0.2.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/muimsd/postile/releases/download/v0.2.0/postile-aarch64-apple-darwin.tar.gz"
      sha256 "613e16dca62611679e72739bd4b563a0a38c831d32a978627d54d508d2c08d41"
    end
    on_intel do
      url "https://github.com/muimsd/postile/releases/download/v0.2.0/postile-x86_64-apple-darwin.tar.gz"
      sha256 "18921871d4defdba54be3228487bc6279b7c7660599b571657993d07fb840364"
    end
  end

  on_linux do
    url "https://github.com/muimsd/postile/releases/download/v0.2.0/postile-x86_64-unknown-linux-gnu.tar.gz"
    sha256 "bde970f389adb50628e0c6bc4c0fadf7cd23e50db76dddd3601c6aed2e2b90dd"
  end

  def install
    bin.install "postile"
  end

  test do
    assert_match "postile", shell_output("\#{bin}/postile --help")
  end
end

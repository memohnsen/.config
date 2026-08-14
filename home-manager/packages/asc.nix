{ lib, buildGoModule, fetchurl }:

buildGoModule rec {
  pname = "asc";
  version = "4.2.0";

  src = fetchurl {
    url = "https://github.com/rorkai/App-Store-Connect-CLI/archive/refs/tags/${version}.tar.gz";
    sha256 = "995d09540c6d5d668ff9edcab126e6b2c61d4263cc4503931202cae2815b7901";
  };

  vendorHash = "sha256-/wEiAVwzVp8ySoRgm21ipouq//hcc7z7nkbW07qpyp8=";
  ldflags = [ "-s" "-w" "-X main.version=${version}" ];
  # The upstream integration tests inspect host Xcode tooling, which is not
  # available inside Nix's isolated build environment.
  doCheck = false;

  postInstall = ''
    mv $out/bin/App-Store-Connect-CLI $out/bin/asc
  '';

  meta = {
    description = "CLI for App Store Connect";
    homepage = "https://asccli.sh";
    license = lib.licenses.mit;
    mainProgram = "asc";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}

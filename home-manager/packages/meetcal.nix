{ lib, stdenvNoCC, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "meetcal";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/meetcal/meetcal-cli/releases/download/v${version}/darwin-arm64.tar.gz";
    sha256 = "008563478e54b96667f7bd898fbfabc01a7dd80e7518dcc18218e1a626d8b2ae";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 meetcal $out/bin/meetcal
    runHook postInstall
  '';

  meta = {
    description = "CLI for querying MeetCal lifting data";
    homepage = "https://github.com/meetcal/meetcal-cli";
    mainProgram = "meetcal";
    platforms = [ "aarch64-darwin" ];
  };
}

{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    rev = "abf477689ecf1524d4ea83bfe1dae8cc8e6a0e34";
    hash = "sha256-XcTx78F0/OwJzK8Kmds4WSw/r59jzri7nzZNffqjSPM=";
  };

  npmDepsHash = "sha256-nYChMn3pZuhY/WZC02xP3x57m1OGN8qGQg+/ecjz494=";

  npmBuildScript = "build";

  meta = {
    description = "ACP server adapter for OpenAI Codex CLI";
    homepage = "https://github.com/agentclientprotocol/codex-acp";
    license = lib.licenses.asl20;
    mainProgram = "codex-acp";
  };
}

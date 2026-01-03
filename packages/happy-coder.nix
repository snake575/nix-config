# Based on nixpkgs package definition:
# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ha/happy-coder/package.nix
#
# To upgrade: update version, set both hashes to "", run switch to get correct hashes from errors
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  nodejs,
  yarnConfigHook,
  yarnBuildHook,
  yarnInstallHook,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "happy-coder";

  # Update version and hashes below to upgrade
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "slopus";
    repo = "happy-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WKzbpxHqE3Dxqy/PDj51tM9+Wl2Pallfrc5UU2MxNn8=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-3/qcbCJ+Iwc+9zPCHKsCv05QZHPUp0it+QR3z7m+ssw=";
  };

  nativeBuildInputs = [
    nodejs
    yarnConfigHook
    yarnBuildHook
    yarnInstallHook
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/happy --prefix PATH : ${lib.makeBinPath [ nodejs ]}
    wrapProgram $out/bin/happy-mcp --prefix PATH : ${lib.makeBinPath [ nodejs ]}
  '';

  meta = {
    description = "Mobile and web client wrapper for Claude Code and Codex with end-to-end encryption";
    homepage = "https://github.com/slopus/happy-cli";
    license = lib.licenses.mit;
    mainProgram = "happy";
    maintainers = with lib.maintainers; [ onsails ];
  };
})

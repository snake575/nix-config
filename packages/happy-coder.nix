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
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "slopus";
    repo = "happy-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-q4o8FHBhZsNL+D8rREjPzI1ky5+p3YNSxKc1OlA2pcs=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = finalAttrs.src + "/yarn.lock";
    hash = "sha256-DlUUAj5b47KFhUBsftLjxYJJxyCxW9/xfp3WUCCClDY=";
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

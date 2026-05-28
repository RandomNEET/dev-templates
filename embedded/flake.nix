{
  description = "A Nix-flake-based Embedded development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

  outputs =
    { self, nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.permittedInsecurePackages = [ "dotnet-sdk-6.0.428" ];
            }
          )
        );
    in
    {
      devShells = forEachSystem (
        pkgs:
        let
          baseUtils = with pkgs; [
            git
            curl
            wget
            neovim
            unzip
            util-linux
          ];
          devTools = with pkgs; [
            gcc-arm-embedded
            openocd
            tio
            dotnet-sdk_6
          ];
          allLibs = baseUtils ++ devTools;
          fhsEnv = pkgs.buildFHSEnv {
            name = "fhs";
            targetPkgs = p: (pkgs.appimageTools.defaultFhsEnvArgs.targetPkgs p) ++ allLibs;
            multiPkgs = p: [ p.zlib ];
            profile = ''
              export HOME="$PWD/.fhs"
              mkdir -p "$HOME"
              export SHELL=zsh
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath allLibs}:$LD_LIBRARY_PATH"
            '';
            runScript = "zsh";
            extraOutputsToInstall = [ "dev" ];
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = [ fhsEnv ];
            shellHook = ''
              echo "FHS environment ready. Type 'fhs' to enter the FHS sub-shell."
              echo "Exit FHS to return to the current shell."
            '';
          };
        }
      );

      formatter = forEachSystem (pkgs: pkgs.nixfmt);
    };
}

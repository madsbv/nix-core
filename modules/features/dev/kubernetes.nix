_: {
  flake.modules.homeManager.kubernetes =
    { lib, pkgs, ... }:
    {
      home.packages = with pkgs; [
        kubectl
        helm
        # minikube bundles its own `kubectl`, which collides with the standalone
        # package in buildEnv. Lowering minikube's priority lets the real
        # kubectl win; `minikube` itself is unique so it is unaffected.
        (lib.lowPrio minikube)
      ];
    };
}

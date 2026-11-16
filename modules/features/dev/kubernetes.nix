_: {
  flake.modules.homeManager.kubernetes =
    { lib, pkgs, ... }:
    {
      home = {
        packages = with pkgs; [
          kubectl
          kubernetes-helm
          kubectx
          kustomize
          sops
          dyff
          skaffold
          stern
          # minikube bundles its own `kubectl`, which collides with the standalone
          # package in buildEnv. Lowering minikube's priority lets the real
          # kubectl win; `minikube` itself is unique so it is unaffected.
          (lib.lowPrio minikube)
        ];

        shellAliases = {
          k = "kubectl";
          kns = "kubens";
          ktx = "kubectx";
          kgn = "kubectl get nodes";
          kb = "${lib.getExe pkgs.kustomize} build --enable-alpha-plugins --enable-exec --load-restrictor=LoadRestrictionsNone";
        };

        # https://github.com/homeport/dyff?tab=readme-ov-file#use-cases-and-examples
        sessionVariables.KUBECTL_EXTERNAL_DIFF = "${pkgs.dyff}/bin/dyff between --omit-header --set-exit-code";
      };

      # Colorized kubectl output; `enableAlias` makes `kubectl` run kubecolor.
      programs.kubecolor = {
        enable = true;
        enableAlias = true;
        settings.objFreshThreshold = "1h";
      };

      programs.kubeswitch = {
        enable = true;
        commandName = "kswitch"; # Default `switch` is too generic
        settings = {
          kind = "SwitchConfig";
          version = "v1alpha1";
          kubeconfigStores = [
            {
              kind = "filesystem";
              kubeconfigName = "config*";
              paths = [ "~/.kube" ];
            }
          ];
        };
      };
    };
}

_: {
  flake.modules.homeManager.k9s = _: {
    programs.k9s = {
      enable = true;
      settings = {
        # $XDG_CONFIG_HOME/k9s/config.yaml
        k9s = {
          # Enable periodic refresh of resource browser windows. Default false
          liveViewAutoRefresh = true;
          # !!New!! v0.50.8...
          # Extends the list of supported GPU vendors. The key is the vendor name, the value must correspond to k8s resource driver designation.
          # Default known GPU vendors:
          # nvidia: nvidia.com/gpu
          # nvidia-shared: nvidia.com/gpu.shared
          # amd: amd.com/gpu
          # intel: gpu.intel.com/i915
          # gpuVendors = {
          #   bozo = "bozo/gpu"; # extends the gpu vendor and add "bozo"
          # };

          # Represents ui poll intervals in seconds. Default 2.0 secs. Minimum value is 2.0 - values below will be capped to the minimum.
          refreshRate = 2;
          # Overrides the default k8s api server requests timeout. Defaults 120s
          apiServerTimeout = "120 s";
          # Number of retries once the connection to the api-server is lost. Default 15.
          maxConnRetry = 5;
          # Indicates whether modification commands like delete/kill/edit are disabled. Default is false
          readOnly = false;
          # This setting allows users to specify the default view, but it is not set by default.
          defaultView = "";
          # Toggles whether k9s should exit when CTRL-C is pressed. When set to true, you will need to exit k9s via the :quit command. Default is false.
          noExitOnCtrlC = false;
          #UI settings
          ui = {
            # Enable mouse support. Default false
            enableMouse = true;
            # Set to true to hide K9s header. Default false
            headless = false;
            # Set to true to hide the K9S logo Default false
            logoless = false;
            # Set to true to hide K9s crumbs. Default false
            crumbsless = false;
            # Set to true to suppress the K9s splash screen on start. Default false. Note that for larger clusters or higher latency connections, there may be no resources visible initially until local caches have finished populating.
            splashless = true;
            # Toggles icons display as not all terminal support these chars. Default: true
            noIcons = false;
            # Toggles reactive UI. This option provide for watching on disk artifacts changes and update the UI live Defaults to false.
            reactive = true;
            # By default all contexts will use the dracula skin unless explicitly overridden in the context config file.
            skin = "monokai"; # => assumes the file skins/dracula.yaml is present in the  $XDG_DATA_HOME/k9s/skins directory. Can be overriden with K9S_SKIN.
            # Convert dark skins to light, or vice versa, preserving hue. Default: false
            invert = false;
            # Allows to set certain views default fullscreen mode. (yaml, helm history, describe, value_extender, details, logs) Default false
            defaultsToFullScreen = false;
            # Show full resource GVR (Group/Version/Resource) vs just R. Default: false.
            useFullGVRTitle = false;
          };
          # Toggles whether k9s should check for the latest revision from the GitHub repository releases. Default is false.
          skipLatestRevCheck = true;
          # # When altering kubeconfig or using multiple kube configs, k9s will clean up clusters configurations that are no longer in use. Setting this flag to true will keep k9s from cleaning up inactive cluster configs. Defaults to false.
          # keepMissingClusters = true;
          # Logs configuration
          logger = {
            # Defines the number of lines to return. Default 100
            tail = 1000;
            # Defines the total number of log lines to allow in the view. Default 1000
            buffer = 50000;
            # Represents how far to go back in the log timeline in seconds. Setting to -1 will tail logs. Default is -1.
            sinceSeconds = -1; # => tail the last 5 mins.
            # Toggles log line wrap. Default false
            textWrap = true;
            # Autoscroll in logs will be disabled. Default is false.
            disableAutoscroll = false;
            # Enable column locking when autoscroll is enabled. Default is false.
            columnLock = true;
            # Toggles log line timestamp info. Default false
            showTime = true;
          };
          thresholds = {
            cpu = {
              critical = 90;
              warn = 70;
            };
            memory = {
              critical = 90;
              warn = 70;
            };
          };
          # Provide shell pod customization when nodeShell feature gate is enabled!
          shellPod = {
            # The shell pod image to use.
            image = "killerAdmin";
            # The namespace to launch to shell pod into.
            namespace = "default";
            # The resource limit to set on the shell pod.
            limits = {
              cpu = "100 m";
              memory = "100 Mi";
            };
            # Enable TTY
            tty = true;
            hostPathVolume = [
              {
                name = "docker-socket";
                # Mount the Docker socket into the shell pod
                mountPath = "/var/run/docker.sock";
                # The path on the host to mount
                hostPath = "/var/run/docker.sock";
                readOnly = true;
              }
            ];
          };
        };
      };
      skins = {
        monokai = ./k9s-monokai.yaml;
      };

      views = {
        "v1/pods" = {
          sortColumn = "NAME:asc";
          columns = [
            "NAMESPACE"
            "NAME"
            "READY"
            "STATUS"
            "CPU"
            "CPU/RL|S"
            "%CPU/R|W"
            "%CPU/L|W"
            "MEM"
            "MEM/RL|S"
            "%MEM/R|W"
            "%MEM/L|W"
            "RESTARTS"
            "LAST RESTART|W"
            "AGE|W"
            "NODE|W"
            "LABELS|H"
            "IP|H"
            "SERVICE-ACCOUNT|H"
            "PF|H"
            "GPU/RL|H"
            "NOMINATED NODE|H"
            "READINESS GATES|H"
            "QOS|H"
            "VALID|H"
          ];
        };
      };

      plugins = {
        # get-all-namespace = {
        #   shortCut = "g";
        #   confirm = false;
        #   description = "get-all";
        #   scopes = [ "namespaces" ];
        #   command = "sh";
        #   background = false;
        #   args = [
        #     "-c"
        #     "kubectl get-all --context $CONTEXT -n $NAME | less -K"
        #   ];
        # };
        get-all-other = {
          shortCut = "g";
          confirm = false;
          description = "get-all";
          scopes = [ "all" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl get-all --context $CONTEXT -n $NAMESPACE | less -K"
          ];
        };

        get-all-resources-by-selected-namespace = {
          shortCut = "m";
          confirm = false;
          description = "List all resources of the selected namespace";
          scopes = [ "namespaces" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "for r in $(kubectl api-resources --verbs=list --namespaced -o name); do out=$(kubectl get --ignore-not-found --show-kind -n $NAME $r 2>/dev/null); if [ -n \"$out\" ]; then echo \"$out\"; echo \"\"; fi; done | less"
          ];
        };
        get-all-resources-in-current-namespace = {
          shortCut = "m";
          confirm = false;
          description = "List all resources of the current namespace";
          scopes = [
            "configmaps"
            "controllerrevisions"
            "daemonsets"
            "deployments"
            "endpoints"
            "endpointslices"
            "events"
            "horizontalpodautoscalers"
            "ingresses"
            "jobs"
            "leases"
            "limitranges"
            "networkpolicies"
            "persistentvolumeclaims"
            "poddisruptionbudgets"
            "pods"
            "replicasets"
            "replicationcontrollers"
            "resourcequotas"
            "rolebindings"
            "roles"
            "secrets"
            "serviceaccounts"
            "services"
            "statefulsets"
          ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "for r in $(kubectl api-resources --verbs=list --namespaced -o name); do out=$(kubectl get --ignore-not-found --show-kind -n $NAMESPACE $r 2>/dev/null); if [ -n \"$out\" ]; then echo \"$out\"; echo \"\"; fi; done | less"
          ];
        };

        helm-default-values = {
          shortCut = "Shift-V";
          confirm = false;
          description = "Chart Default Values";
          scopes = [ "helm" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "revision=$(helm history -n $NAMESPACE --kube-context $CONTEXT $COL-NAME | grep deployed | cut -d$'\\t' -f1 | tr -d ' \\t'); kubectl get secrets --context $CONTEXT -n $NAMESPACE sh.helm.release.v1.$COL-NAME.v$revision -o yaml | yq -e '.data.release' - | base64 -d | base64 -d | gunzip | jq -r '.chart.values' | yq -y | less -K"
          ];
        };

        helm-values = {
          shortCut = "v";
          confirm = false;
          description = "Chart Values";
          scopes = [ "helm" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "helm get values $COL-NAME -n $NAMESPACE --kube-context $CONTEXT | less -K"
          ];
        };

        raw-logs-follow = {
          shortCut = "Ctrl-G";
          description = "logs -f";
          scopes = [ "po" ];
          command = "kubectl";
          background = false;
          args = [
            "logs"
            "-f"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
            "--kubeconfig"
            "$KUBECONFIG"
          ];
        };
        log-less = {
          shortCut = "Shift-K";
          description = "logs|less";
          scopes = [ "po" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            "\"$@\" | less"
            "dummy-arg"
            "kubectl"
            "logs"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
            "--kubeconfig"
            "$KUBECONFIG"
          ];
        };
        log-less-container = {
          shortCut = "Shift-L";
          description = "logs|less";
          scopes = [ "containers" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            "\"$@\" | less"
            "dummy-arg"
            "kubectl"
            "logs"
            "-c"
            "$NAME"
            "$POD"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
            "--kubeconfig"
            "$KUBECONFIG"
          ];
        };

        stern = {
          shortCut = "Ctrl-Y";
          confirm = false;
          description = "Logs <Stern>";
          scopes = [ "pods" ];
          command = "stern";
          background = false;
          args = [
            "--tail"
            "50"
            "$FILTER"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
          ];
        };

        watch-events = {
          shortCut = "Shift-E";
          confirm = false;
          description = "Get Events";
          scopes = [ "all" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl events --context $CONTEXT --namespace $NAMESPACE --for $RESOURCE_NAME.\${RESOURCE_GROUP:+.RESOURCE_GROUP}/$NAME --watch"
          ];
        };

        ## Nix krr package broken
        # krr = {
        #   shortCut = "Shift-K";
        #   description = "Get krr";
        #   scopes = [
        #     "deployments"
        #     "daemonsets"
        #     "statefulsets"
        #     "cronjobs"
        #   ];
        #   command = "bash";
        #   background = false;
        #   confirm = false;
        #   args = [
        #     "-c"
        #     "LABELS=$(kubectl get $RESOURCE_NAME $NAME -n $NAMESPACE  --context $CONTEXT  --show-labels | awk '{print $NF}' | awk '{if(NR>1)print}')\nkrr simple --cluster $CONTEXT --selector $LABELS \necho \"Press 'q' to exit\"\nwhile : ; do\nread -n 1 k <&1\nif [[ $k = q ]] ; then\nbreak\nfi\ndone\n"
        #   ];
        # };
        # krr-ns = {
        #   shortCut = "Shift-K";
        #   description = "Get krr";
        #   scopes = [ "namespaces" ];
        #   command = "bash";
        #   background = false;
        #   confirm = false;
        #   args = [
        #     "-c"
        #     "krr simple --cluster $CONTEXT -n $RESOURCE_NAME\necho \"Press 'q' to exit\"\nwhile : ; do\nread -n 1 k <&1\nif [[ $k = q ]] ; then\nbreak\nfi\ndone"
        #   ];
        # };
      };
    };
  };
}

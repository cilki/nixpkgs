{ pkgs, ... }:

# Smoke test: spin up a NixOS machine with services.goldboot enabled and
# verify the daemon comes up, anonymous requests are rejected with 401,
# and bad passwords return 401 with no information disclosure.

{
  name = "goldboot-registry";
  meta = { };

  nodes.machine = { ... }: {
    # Drop the argon2id hash into /etc rather than /nix/store so the
    # module's anti-foot-gun assertion (no store paths for password
    # hashes) is satisfied. In production this file would be managed by
    # sops-nix / agenix.
    environment.etc."goldboot-registry/alice.hash".text = ''
      $argon2id$v=19$m=19456,t=2,p=1$YQAAAAAAAAAAAAAAAAAAAA$0r/W2/dXqAvjVcg0nKKM2tn3wkvMOJjXAg8DZpwIPng
    '';

    services.goldboot = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 3000;
      openFirewall = false;
      users.alice = {
        passwordHashFile = "/etc/goldboot-registry/alice.hash";
        pull = true;
        push = true;
      };
    };
    environment.systemPackages = [ pkgs.curl pkgs.jq ];
  };

  testScript = ''
    machine.wait_for_unit("goldboot-registry.service")
    machine.wait_for_open_port(3000)

    # Anonymous list → 401
    status = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/v1/images"
    ).strip()
    assert status == "401", f"expected 401 for anonymous request, got {status}"

    # Wrong password → 401
    bad = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' "
        "-d '{\"username\":\"alice\",\"password\":\"wrong\"}' "
        "http://127.0.0.1:3000/v1/auth/login"
    ).strip()
    assert bad == "401", f"expected 401 for wrong password, got {bad}"

    # Missing user → also 401 (no information disclosure)
    nobody = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' "
        "-d '{\"username\":\"nobody\",\"password\":\"x\"}' "
        "http://127.0.0.1:3000/v1/auth/login"
    ).strip()
    assert nobody == "401", f"expected 401 for missing user, got {nobody}"

    # Verify the generated config file has restrictive permissions
    perms = machine.succeed("stat -c %a /run/goldboot-registry/config.toml").strip()
    assert perms == "640", f"expected mode 640, got {perms}"

    # The hash file must not have leaked via journalctl
    machine.fail(
        "journalctl -u goldboot-registry --no-pager | grep -q argon2id"
    )
  '';
}

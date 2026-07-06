{ pkgs, ... }:

# Smoke test: spin up a NixOS machine running the goldboot registry behind
# the module's nginx reverse proxy and verify that the backend serves plain
# HTTP while nginx enforces Basic Auth.

{
  name = "goldboot-registry";
  meta.maintainers = with pkgs.lib.maintainers; [ cilki ];

  nodes.machine =
    { pkgs, ... }:
    {
      services.goldboot-registry = {
        enable = true;
        nginx = {
          enable = true;
          hostname = "registry.test";
          # A store path is fine for a throwaway test credential; real
          # deployments should keep the htpasswd file outside the store.
          basicAuthFile = pkgs.runCommand "htpasswd" { } ''
            ${pkgs.apacheHttpd}/bin/htpasswd -nbB alice password > $out
          '';
        };
      };
      networking.hosts."127.0.0.1" = [ "registry.test" ];
      environment.systemPackages = [ pkgs.curl ];
    };

  testScript = ''
    machine.wait_for_unit("goldboot-registry.service")
    machine.wait_for_open_port(3000)
    machine.wait_for_unit("nginx.service")
    machine.wait_for_open_port(80)

    # The backend itself is unauthenticated plain HTTP
    status = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/v1/images"
    ).strip()
    assert status == "200", f"expected 200 from the backend, got {status}"

    # Via nginx without credentials -> 401
    anon = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' http://registry.test/v1/images"
    ).strip()
    assert anon == "401", f"expected 401 via nginx without credentials, got {anon}"

    # Wrong credentials -> 401
    bad = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' -u alice:wrong http://registry.test/v1/images"
    ).strip()
    assert bad == "401", f"expected 401 via nginx with bad credentials, got {bad}"

    # Valid credentials -> 200
    ok = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' -u alice:password http://registry.test/v1/images"
    ).strip()
    assert ok == "200", f"expected 200 via nginx with credentials, got {ok}"

    # An authenticated upload reaches the registry (which rejects the bogus
    # body itself) instead of being cut off by nginx (413 or 401)
    push = machine.succeed(
        "curl -s -o /dev/null -w '%{http_code}' -u alice:password "
        "-X PUT --data-binary 'not a goldboot image' "
        "http://registry.test/v1/images/test/tags/latest"
    ).strip()
    assert push not in ("401", "413"), f"upload blocked by nginx with {push}"
  '';
}

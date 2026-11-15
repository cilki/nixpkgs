# Exercises the three fossdb services together on one host, and the API key
# lifecycle that ties them together.
#
# The interesting behaviour here is the bootstrap: collector and worker keys
# do not exist until the server mints them, so fossdb-provision has to run
# against the live admin socket before either agent can authenticate.
{ lib, ... }: {
  name = "fossdb";

  meta.maintainers = with lib.maintainers; [ cilki ];

  nodes.machine = { pkgs, ... }: {
    services.fossdb.server = {
      enable = true;
      hostName = "fossdb.local";
      # The test has no DNS or ACME server.
      enableACME = false;
      useACMEHost = null;
      publicBaseUrl = "http://fossdb.local";
      # Reap unsubscribed accounts aggressively so the test can observe it.
      accountGraceHours = 1;
    };

    services.fossdb.collector.enable = true;
    services.fossdb.worker.enable = true;

    # nginx would otherwise insist on TLS for a host we cannot certify.
    services.nginx.virtualHosts."fossdb.local".forceSSL = lib.mkForce false;

    networking.hosts."127.0.0.1" = [ "fossdb.local" ];

    environment.systemPackages = [ pkgs.curl pkgs.jq ];
  };

  testScript = ''
    machine.wait_for_unit("fossdb-server.service")
    machine.wait_for_open_port(3000)

    with subtest("server is healthy"):
        machine.succeed("curl -sf http://127.0.0.1:3000/api/health | jq -e '.status == \"healthy\"'")

    with subtest("admin socket is group-restricted"):
        machine.wait_for_file("/run/fossdb/admin.sock")
        mode = machine.succeed("stat -c %A /run/fossdb/admin.sock").strip()
        assert mode.startswith("s"), f"not a socket: {mode}"
        assert mode[7:] == "---", f"admin socket is accessible to others: {mode}"

    with subtest("provisioning mints one key per local component"):
        machine.wait_for_unit("fossdb-provision.service")
        machine.wait_for_file("/var/lib/fossdb/keys/collector.key")
        machine.wait_for_file("/var/lib/fossdb/keys/worker.key")

        keys = machine.succeed(
            "fossdb admin --socket /run/fossdb/admin.sock --json api-key list"
        )
        roles = machine.succeed(
            f"echo {keys!r} | jq -r '.[].role' | sort | tr '\\n' ' '"
        ).strip()
        assert roles == "collector worker", f"unexpected roles: {roles}"

    with subtest("provisioned keys are not world-readable"):
        for role in ["collector", "worker"]:
            mode = machine.succeed(f"stat -c %A /var/lib/fossdb/keys/{role}.key").strip()
            assert mode[7:] == "---", f"{role} key is world-readable: {mode}"

    with subtest("agents authenticate with their provisioned keys"):
        machine.wait_for_unit("fossdb-collector.service")
        machine.wait_for_unit("fossdb-worker.service")

        # A 401 would appear in the agent logs if the key were rejected.
        machine.fail("journalctl -u fossdb-worker.service | grep -qi 'unauthorized'")
        machine.fail("journalctl -u fossdb-collector.service | grep -qi 'unauthorized'")

        # And the server should have recorded both keys as recently seen.
        machine.succeed(
            "fossdb admin --socket /run/fossdb/admin.sock --json api-key list "
            "| jq -e 'all(.[]; .last_used_at != null)'"
        )

    with subtest("accounts are created with an id and nothing else"):
        user_id = machine.succeed(
            "curl -sf -X POST http://127.0.0.1:3000/api/auth/register | jq -r .user_id"
        ).strip()
        assert user_id.startswith("fdb_"), f"unexpected account id: {user_id}"

        # The id is the whole credential.
        machine.succeed(
            f"curl -sf -H 'Authorization: Bearer {user_id}' "
            "http://127.0.0.1:3000/api/users/subscriptions | jq -e '.subscriptions == []'"
        )

    with subtest("feeds are served for a valid account id"):
        machine.succeed(
            f"curl -sf http://127.0.0.1:3000/feed/{user_id}/atom.xml | grep -q '<feed'"
        )
        machine.succeed(
            f"curl -sf http://127.0.0.1:3000/feed/{user_id}/rss.xml | grep -q '<rss'"
        )
        # An unknown id must not be distinguishable from a malformed one.
        machine.succeed(
            "test $(curl -s -o /dev/null -w %{http_code} "
            "http://127.0.0.1:3000/feed/fdb_0000000000000000000000000x/atom.xml) = 404"
        )

    with subtest("nginx proxies the api and serves the frontend"):
        machine.wait_for_unit("nginx.service")
        machine.succeed("curl -sf http://fossdb.local/api/health | jq -e '.status'")

    with subtest("revoking a key stops it working"):
        key_id = machine.succeed(
            "fossdb admin --socket /run/fossdb/admin.sock --json api-key list "
            "| jq -r '[.[] | select(.role == \"worker\")][0].key_id'"
        ).strip()
        worker_key = machine.succeed("cat /var/lib/fossdb/keys/worker.key").strip()

        machine.succeed(
            f"fossdb admin --socket /run/fossdb/admin.sock api-key revoke {key_id}"
        )
        machine.succeed(
            f"test $(curl -s -o /dev/null -w %{{http_code}} "
            f"-H 'Authorization: Bearer {worker_key}' "
            "http://127.0.0.1:3002/packages/next) = 401"
        )

        # Revoked keys are hidden by default and visible with --all.
        machine.succeed(
            "fossdb admin --socket /run/fossdb/admin.sock --json api-key list "
            f"| jq -e 'all(.[]; .key_id != \"{key_id}\")'"
        )
        machine.succeed(
            "fossdb admin --socket /run/fossdb/admin.sock --json api-key list --all "
            f"| jq -e 'any(.[]; .key_id == \"{key_id}\" and .revoked_at != null)'"
        )

    with subtest("provisioning reissues a revoked key"):
        machine.succeed("systemctl restart fossdb-provision.service")
        machine.wait_for_unit("fossdb-provision.service")

        reissued = machine.succeed("cat /var/lib/fossdb/keys/worker.key").strip()
        assert reissued != worker_key, "revoked key was not replaced"

        machine.succeed(
            f"test $(curl -s -o /dev/null -w %{{http_code}} "
            f"-H 'Authorization: Bearer {reissued}' "
            "http://127.0.0.1:3002/packages/next) = 404"
        )

    with subtest("admin reports describe the running deployment"):
        machine.succeed("fossdb admin --socket /run/fossdb/admin.sock status")
        machine.succeed("fossdb admin --socket /run/fossdb/admin.sock collectors")
        machine.succeed("fossdb admin --socket /run/fossdb/admin.sock workers")

    with subtest("internal apis are not reachable from off-host"):
        # internalListenAddress defaults to loopback, so these must not be
        # bound on the external interface.
        machine.fail("ss -ltn | grep -E '0\\.0\\.0\\.0:(3001|3002)'")
  '';
}

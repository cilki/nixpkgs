{ fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "sandpolis-server";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "fossable";
    repo = "sandpolis";
    rev = version;
    hash = "sha256-gyWnahj1A+iXUQlQ1O1H1u7K5euYQOld9qWm99Vjaeg=";
  };

  sourceRoot = "sandpolis";
  buildFeatures = [ "server" ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-9atn5qyBDy4P6iUoHFhg+TV6Ur71fiah4oTJbBMeEy4=";
}

# Aggregates all home-manager modules
{...}: {
  imports = [
    ./programs
    ./services
  ];
}

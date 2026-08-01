{
  inputs,
}:
{
  system,
  nodes ? { },
}:
{
  deploy = nodes;
  checks = inputs.deploy-rs.lib.${system}.deployChecks nodes;
}

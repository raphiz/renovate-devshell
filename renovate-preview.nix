{
  writeShellApplication,
  jq,
  gnused,
  coreutils,
  renovate,
  ...
}:
writeShellApplication {
  name = "renovate-preview";
  runtimeInputs = [jq gnused coreutils renovate];
  runtimeEnv.RENOVATE_PREVIEW_JQ = ./renovate-preview.jq;
  text = builtins.readFile ./renovate-preview.sh;
}

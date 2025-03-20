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
  text =
    builtins.readFile ./renovate-preview.sh
    + ''
      jq --argjson showFiles $listFiles -r -f "${./renovate-preview.jq}" "$packageFilesJSON"
    '';
}

deviceName:
{ osConfig }:

rec {
  getSecretPath = let
    dummySecrets = osConfig.custom.useDummySecrets;
    secretsFolder = if dummySecrets then "/example_secrets" else "/secrets";
  in basePath: offsetPath: let
    secretsBase = basePath + secretsFolder;
    generalSecretPath = secretsBase + ("/" + offsetPath);

    # determine the device specific secret path
    deviceSecretsBase = secretsBase + ("/" + deviceName);
    deviceSecretPath = deviceSecretsBase + ("/" + offsetPath);

    # Prefer the device specific secret path (if it exists) over the common secrets path
    secretPath = if (builtins.pathExists deviceSecretPath) then deviceSecretPath else generalSecretPath;
  in
    secretPath;

    getSecret = basePath: offsetPath:
      import (
        getSecretPath basePath offsetPath
      );

    # Network port tools
    definePortTCP = port: desc: { inherit port desc; tcp = true;};
    definePortUDP = port: desc: { inherit port desc; udp = true;};
    definePortTCPnUDP = port: desc: (definePortTCP port desc) // (definePortUDP port desc);
    defineHiddenPortTCP = port: desc: { inherit port desc; tcp = true; hidden = true;};
    defineHiddenPortUDP = port: desc: { inherit port desc; udp = true; hidden = true;};
    defineHiddenPortTCPnUDP = port: desc: (defineHiddenPortTCP port desc) // (defineHiddenPortUDP port desc);

    defaultPortDef = {
        tcp = false;
        udp = false;
        hidden = false;
    };

    extractPort = portCollection: desc: let
            matches = builtins.filter (x: x.desc == desc) portCollection;
        in
            assert (builtins.length matches) == 1; (builtins.elemAt matches 0).port;

    collectPorts = portCollection: builtins.map (x: x.port) portCollection;

    getAllExposedXPorts = portAttr: portDefSet:
      let
          portDefs = builtins.attrValues portDefSet;
          portDefList = builtins.concatLists portDefs;
          filteredPortDefList = builtins.filter
            (x: (builtins.getAttr portAttr (defaultPortDef // x)))
            portDefList;

          # I am aware that this is somewhat redundant but that way we can add checks for duplicate port assignments!
          hidden_ports = builtins.map (x: toString x.port)
            (builtins.filter (x: (defaultPortDef // x).hidden) filteredPortDefList);
          ports = builtins.map (x: x.port) filteredPortDefList;
          portSize = builtins.length ports;
          uniquePortSize = builtins.length (builtins.attrNames (builtins.groupBy (x: toString x) ports));
          uniquePorts = assert portSize == uniquePortSize; builtins.attrValues (builtins.removeAttrs
            (builtins.mapAttrs (name: value:
                (builtins.elemAt value 0)
              )
              (builtins.groupBy (x: toString x) ports)
            )
           hidden_ports);
      in uniquePorts;

    getAllExposedUDPports = portDefSet: getAllExposedXPorts "udp" portDefSet;
    getAllExposedTCPports = portDefSet: getAllExposedXPorts "tcp" portDefSet;
}

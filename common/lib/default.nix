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
    defineInternetExposedPortTCP = port: desc: { inherit port desc; tcp = true; expose_to_internet = true;};
    defineInternetExposedPortUDP = port: desc: { inherit port desc; udp = true; expose_to_internet = true;};
    defineInternetExposedPortTCPnUDP = port: desc: (defineInternetExposedPortTCP port desc) // (defineInternetExposedPortUDP port desc);
    defineHiddenPortTCP = port: desc: { inherit port desc; tcp = true; hidden = true;};
    defineHiddenPortUDP = port: desc: { inherit port desc; udp = true; hidden = true;};
    defineHiddenPortTCPnUDP = port: desc: (defineHiddenPortTCP port desc) // (defineHiddenPortUDP port desc);

    defaultPortDef = {
      tcp = false;
      udp = false;
      hidden = false;
      expose_to_internet = false;
    };

    extractPort = portCollection: desc: let
        matches = builtins.filter (x: x.desc == desc) portCollection;
      in
        assert (builtins.length matches) == 1; (builtins.elemAt matches 0).port;

    collectPorts = portCollection: builtins.map (x: x.port) portCollection;

    getAllLocallyExposedXPorts = portAttr: portDefSet:
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
        # Remove all hidden from the port list to obtain all ports that are supposed to be exposed to the local network
        uniquePorts = assert portSize == uniquePortSize; builtins.attrValues (builtins.removeAttrs
          (builtins.mapAttrs 
            (name: value: (builtins.elemAt value 0))
            (builtins.groupBy (x: toString x) ports)
          )
          hidden_ports);
      in uniquePorts;

    getAllInternetExposedXPorts = portAttr: portDefSet:
      let
        portDefs = builtins.attrValues portDefSet;
        portDefList = builtins.concatLists portDefs;
        filteredPortDefList = builtins.filter
          (x: (builtins.getAttr portAttr (defaultPortDef // x)))
          portDefList;

        # I am aware that this is somewhat redundant but that way we can add checks for duplicate port assignments!
        non_globally_exposed_ports = builtins.map (x: toString x.port)
          (builtins.filter (x: !(defaultPortDef // x).expose_to_internet) filteredPortDefList);
        ports = builtins.map (x: x.port) filteredPortDefList;
        portSize = builtins.length ports;
        uniquePortSize = builtins.length (builtins.attrNames (builtins.groupBy (x: toString x) ports));
        # Remove all non_globally_exposed_ports from the port list to obtain all ports that are supposed to be exposed to the internet
        uniquePorts = assert portSize == uniquePortSize; builtins.attrValues (builtins.removeAttrs
          (builtins.mapAttrs 
            (name: value: (builtins.elemAt value 0))
            (builtins.groupBy (x: toString x) ports)
          )
          non_globally_exposed_ports);
      in uniquePorts;

    getAllLocallyExposedUDPports = portDefSet: getAllLocallyExposedXPorts "udp" portDefSet;
    getAllLocallyExposedTCPports = portDefSet: getAllLocallyExposedXPorts "tcp" portDefSet;

    getAllInternetExposedUDPports = portDefSet: getAllInternetExposedXPorts "udp" portDefSet;
    getAllInternetExposedTCPports = portDefSet: getAllInternetExposedXPorts "tcp" portDefSet;
}

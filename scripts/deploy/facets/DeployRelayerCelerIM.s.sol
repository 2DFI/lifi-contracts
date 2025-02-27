// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { DeployScriptBase } from "./utils/DeployScriptBase.sol";
import { stdJson } from "forge-std/Script.sol";
import { RelayerCelerIM } from "lifi/Periphery/RelayerCelerIM.sol";

contract DeployScript is DeployScriptBase {
    using stdJson for string;

    constructor() DeployScriptBase("RelayerCelerIM") {}

    function run()
        public
        returns (RelayerCelerIM deployed, bytes memory constructorArgs)
    {
        string memory path = string.concat(
            vm.projectRoot(),
            "/config/cbridge.json"
        );
        string memory json = vm.readFile(path);
        address messageBus = json.readAddress(
            string.concat(".", network, ".messageBus")
        );

        if (messageBus == address(32)) {
            revert("MessageBus not found in cBridge config file");
        }

        path = string.concat(
            root,
            "/deployments/",
            network,
            ".",
            fileSuffix,
            "json"
        );
        json = vm.readFile(path);
        address diamond = json.readAddress(".LiFiDiamond");
        if (diamond == address(32)) {
            revert("LiFiDiamond not found in deployments file");
        }

        constructorArgs = abi.encode(deployerAddress, messageBus, diamond);

        vm.startBroadcast(deployerPrivateKey);

        if (isDeployed()) {
            return (RelayerCelerIM(payable(predicted)), constructorArgs);
        }

        deployed = RelayerCelerIM(
            payable(
                factory.deploy(
                    salt,
                    bytes.concat(
                        type(RelayerCelerIM).creationCode,
                        constructorArgs
                    )
                )
            )
        );

        vm.stopBroadcast();
    }
}

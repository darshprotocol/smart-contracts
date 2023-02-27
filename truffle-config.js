const HDWalletProvider = require('@truffle/hdwallet-provider');

const dotenv = require("dotenv")
dotenv.config()

const MNEMONIC = process.env.MNEMONIC;

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1", // Localhost (default: none)
            port: 7545, // Standard Ethereum port (default: none)
            network_id: "*", // Any network (default: none)
        },

        test: {
            host: "127.0.0.1", // Localhost (default: none)
            port: 7545, // Standard Ethereum port (default: none)
            network_id: "*", // Any network (default: none)
        },

        fantom: {
            provider: () => new HDWalletProvider(MNEMONIC, 'https://fantom-testnet.public.blastapi.io'),
            network_id: 4002,
            confirmations: 2,
            timeoutBlocks: 9999999,
            skipDryRun: true,
            networkCheckTimeout: 999999999
        },

        test2: {
            provider: () => new HDWalletProvider(MNEMONIC, 'https://rpc.ankr.com/fantom_testnet'),
            network_id: 4002,
            confirmations: 2,
            timeoutBlocks: 9999999,
            skipDryRun: true,
            networkCheckTimeout: 999999999
        }
    },

    // Set default mocha options here, use special reporters, etc.
    mocha: {
        // timeout: 100000
    },

    // Configure your compilers
    compilers: {
        solc: {
            version: "0.8.17", // Fetch exact version from solc-bin (default: truffle's version)
            // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
            settings: { // See the solidity docs for advice about optimization and evmVersion
                optimizer: {
                    enabled: true,
                    runs: 200
                },
                viaIR: true
                //  evmVersion: "byzantium"
            }
        }
    }
};
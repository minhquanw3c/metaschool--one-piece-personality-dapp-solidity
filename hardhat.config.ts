import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import dotenv from "dotenv";

dotenv.config();

function privateKey() {
	return process.env.PRIVATE_KEY !== undefined
		? [process.env.PRIVATE_KEY]
		: [];
}

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.20",
		settings: {
			optimizer: {
				enabled: true,
				runs: 1000,
			},
		},
	},
	networks: {
		polygon_amoy: {
			url: "https://polygon-amoy.drpc.org",
			accounts: privateKey(),
		},
		arbitrum_sepolia: {
			url: "https://arbitrum-sepolia.blockpi.network/v1/rpc/public",
			accounts: privateKey(),
		},
	},
	etherscan: {
		apiKey: process.env.API_KEY,
		customChains: [
			{
				network: "arbitrum_sepolia",
				chainId: 421614,
				urls: {
					apiURL: "https://api-sepolia.arbiscan.io/api",
					browserURL: "https://sepolia.arbiscan.io/",
				},
			},
		],
	},
};

export default config;

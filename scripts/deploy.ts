const { ethers } = require("hardhat");
const fs = require("fs");
const dotenv = require("dotenv");

dotenv.config();

async function main() {
	const [deployer] = await ethers.getSigners();
	console.log("Deploying contracts with the account:", deployer.address);

	const vrfCoordinatorV2Address = process.env.VRF_ADDRESS;
	const subscriptionId = process.env.SUB_ID;
	const subscriptionKeyHash = process.env.KEY_HASH;
	const gasLimit = 2000000;

	const argumentsArray = [
		vrfCoordinatorV2Address,
		subscriptionId,
		subscriptionKeyHash,
		gasLimit,
	];

	const content =
		"module.exports = " + JSON.stringify(argumentsArray, null, 2) + ";";

	fs.writeFileSync("./arguments.js", content);
	console.log("arguments.js file generated successfully.");
	console.log(content);

	const OnePiecePersonalityDapp = await ethers.getContractFactory(
		"OnePieceMint"
	);
	console.log("Deploying OnePiecePersonalityDapp...");

	try {
		const onePiecePersonalityDapp = await OnePiecePersonalityDapp.deploy(
			vrfCoordinatorV2Address,
			subscriptionId,
			subscriptionKeyHash,
			gasLimit
		);

		console.log(
			"OnePiecePersonalityDapp deployed to: ",
			await onePiecePersonalityDapp.getAddress()
		);
	} catch (error: unknown) {
		if (error instanceof TypeError) {
			console.error(error);
		}
	}
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

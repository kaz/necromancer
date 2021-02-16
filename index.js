"use strict";

const Compute = require("@google-cloud/compute");
const compute = new Compute();
const vm = compute.zone(process.env.ZONE).vm(process.env.VM);

const run = async () => {
	const [{ status }] = await vm.getMetadata();
	if (status != "TERMINATED") {
		console.log(`Current VM status is ${status}. Waiting for VM to be TERMINATED ...`);
		await vm.waitFor("TERMINATED");
	}

	console.log(`Restarting VM ...`);
	return vm.start();
};

module.exports = { run };

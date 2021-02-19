"use strict";

const Compute = require("@google-cloud/compute");
const compute = new Compute();

const resurrect = async ({ data }) => {
	const params = new URLSearchParams(Buffer.from(data || "", "base64").toString());

	const zone = params.get("zone");
	const instance = params.get("instance");
	const timeoutStr = params.get("timeout");
	const timeout = parseInt(timeoutStr || "0");

	const vm = compute.zone(zone).vm(instance);
	const [{ status }] = await vm.getMetadata();

	if (!timeout && status == "RUNNING") {
		return;
	}
	if (timeout && status != "TERMINATED") {
		console.log(`Current VM status is ${status}. Waiting for VM to be TERMINATED ...`);
		await vm.waitFor("TERMINATED", { timeout }).catch(() => console.error("[!] Timed out"));
	}

	console.log("Restarting VM ...");
	return vm.start();
};

module.exports = { resurrect };

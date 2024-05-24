import { getAccountAddress, getServiceAddress } from "@onflow/flow-js-testing";
import { testsUtils } from "../../_utils/tests.utils";
import { MFLPackTemplateTestsUtils } from './MFLPackTemplateTests.utils';

export const MFLPackTestsUtils = {
  async deployMFLPackContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract("NonFungibleToken", serviceAddress, "_libs/NonFungibleToken", addressMap);
    await testsUtils.deployContract("MetadataViews", serviceAddress, "_libs/MetadataViews", addressMap);
    await testsUtils.deployContract("MFLAdmin", to, "core/MFLAdmin", addressMap);
    await testsUtils.deployContract("MFLPackTemplate", to, "packs/MFLPackTemplate", addressMap);
    await testsUtils.deployContract("MFLViews", to, "views/MFLViews", addressMap);
    await testsUtils.deployContract("MFLPack", to, "packs/MFLPack", addressMap);
    await testsUtils.deployContract("MFLClub", to, "clubs/MFLClub", addressMap);
    await testsUtils.deployContract("MFLPlayer", to, "players/MFLPlayer", addressMap);
    return addressMap;
  },

  async initPackTemplate(rootAdminAccountName, receiverAccountName, argsPackTemplate) {
    await MFLPackTemplateTestsUtils.createPackTemplateAdmin(rootAdminAccountName, receiverAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);
    await testsUtils.shallPass({
      name: "mfl/packs/create_pack_template.tx",
      args: argsPackTemplate,
      signers: [receiverAcctAddress],
    });
  },

  async createPackAdmin(rootAdminAccountName, receiverAccountName) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({ name: "mfl/core/create_admin_proxy.tx", signers: [receiverAcctAddress] });
    const args = [receiverAcctAddress, `/private/${receiverAccountName}-packAdminClaim`];
    await testsUtils.shallPass({
      name: "mfl/packs/give_pack_admin_claim.tx",
      args,
      signers: [rootAdminAcctAddress],
    });
  },
};

import { getAccountAddress, getServiceAddress } from "flow-js-testing";
import { testsUtils } from "../../_utils/tests.utils";

export const FOUNDATION_LICENSE_ARGS = {
  foundationLicenseSerialNumber: 123,
  foundationLicenseCity: "Paris",
  foundationLicenseCountry: "France",
  foundationLicenseSeason: 1,
  foundationLicenseCID: "Qabcdef",
};

export const MFLClubTestsUtils = {
  async deployMFLClubContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract("NonFungibleToken", serviceAddress, "_libs/NonFungibleToken", addressMap);
    await testsUtils.deployContract("MetadataViews", serviceAddress, "_libs/MetadataViews", addressMap);
    await testsUtils.deployContract("MFLAdmin", to, "core/MFLAdmin", addressMap);
    await testsUtils.deployContract("MFLClub", to, "clubs/MFLClub", addressMap);
    return addressMap;
  },

  async createClubAndSquadAdmin(rootAdminAccountName, receiverAccountName, isClubAdmin = true, isSquadAdmin = false) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({ name: "mfl/core/create_admin_proxy.tx", signers: [receiverAcctAddress] });
    if (isClubAdmin) {
      const argsClubAdmin = [receiverAcctAddress, `/private/${receiverAccountName}-clubAdminClaim`];
      await testsUtils.shallPass({
        name: "mfl/clubs/give_club_admin_claim.tx",
        args: argsClubAdmin,
        signers: [rootAdminAcctAddress],
      });
    }

    if (isSquadAdmin) {
      const argsSquadAdmin = [receiverAcctAddress, `/private/${receiverAccountName}-squadAdminClaim`];
      await testsUtils.shallPass({
        name: "mfl/clubs/squads/give_squad_admin_claim.tx",
        args: argsSquadAdmin,
        signers: [rootAdminAcctAddress],
      });
    }
    return receiverAcctAddress;
  },

  async createClubNFT(clubID, squadID, playerAdminAccountName = "AliceAdminAccount") {
    const adminAccountAddress = await getAccountAddress(playerAdminAccountName);
    const signers = [adminAccountAddress];
    const args = [clubID, ...Object.values(FOUNDATION_LICENSE_ARGS), squadID, "squadType", adminAccountAddress];
    return await testsUtils.shallPass({ name: "mfl/clubs/mint_club_and_squad.tx", args, signers });
  },

  FOUNDATION_LICENSE: {
    ...FOUNDATION_LICENSE_ARGS,
    foundationLicenseCID: undefined,
    foundationLicenseImage: {
      cid: FOUNDATION_LICENSE_ARGS.foundationLicenseCID,
      path: null,
    },
  },
};

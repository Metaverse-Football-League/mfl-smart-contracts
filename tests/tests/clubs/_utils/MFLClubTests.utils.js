import { getAccountAddress, getServiceAddress } from "flow-js-testing";
import { testsUtils } from "../../_utils/tests.utils";

const FOUNDATION_LICENSE_ARGS = {
  foundationLicenseSerialNumber: 123,
  foundationLicenseCity: "Paris",
  foundationLicenseCountry: "France",
  foundationLicenseSeason: 1,
  foundationLicenseCID: "Qabcdef",
};

const CLUB_INFO_ARGS = {
  name: "The Club",
  description: "This is the best club",
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

  async createClubNFT(clubID, squadID, shallPass = true, clubAdminAccountName = "AliceAdminAccount") {
    const adminAccountAddress = await getAccountAddress(clubAdminAccountName);
    const signers = [adminAccountAddress];
    const args = [clubID, ...Object.values(FOUNDATION_LICENSE_ARGS), squadID, "squadType", 42, 1, adminAccountAddress];
    if (shallPass) {
      return await testsUtils.shallPass({ name: "mfl/clubs/mint_club_and_squad.tx", args, signers });
    } else {
      return await testsUtils.shallRevert({ name: "mfl/clubs/mint_club_and_squad.tx", args, signers });
    }
  },

  async foundClub(clubID, clubName, clubDescription, shallPass = true, clubAdminAccountName = "AliceAdminAccount") {
    const adminAccountAddress = await getAccountAddress(clubAdminAccountName);
    const signers = [adminAccountAddress];
    const args = [clubID, clubName ?? CLUB_INFO_ARGS.name, clubDescription ?? CLUB_INFO_ARGS.description];
    if (shallPass) {
      return await testsUtils.shallPass({ name: "mfl/clubs/found_club.tx", args, signers });
    } else {
      return await testsUtils.shallRevert({ name: "mfl/clubs/found_club.tx", args, signers });
    }
  },

  FOUNDATION_LICENSE: {
    ...FOUNDATION_LICENSE_ARGS,
    foundationLicenseCID: undefined,
    foundationLicenseImage: {
      cid: FOUNDATION_LICENSE_ARGS.foundationLicenseCID,
      path: null,
    },
  },

  CLUB_INFO: {
    ...CLUB_INFO_ARGS,
  },

  CLUB_STATUS_RAW_VALUES: {
    NOT_FOUNDED: 0,
    PENDING_VALIDATION: 1,
    FOUNDED: 2,
  },

  SQUAD_STATUS_RAW_VALUES: {
    ACTIVE: 0,
  },
};

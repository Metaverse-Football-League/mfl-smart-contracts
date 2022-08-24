import { emulator, getAccountAddress } from "flow-js-testing";
import { MFLClubTestsUtils } from "./_utils/MFLClubTests.utils";
import { testsUtils } from "../_utils/tests.utils";
import * as matchers from "jest-extended";

expect.extend(matchers);
jest.setTimeout(40000);

describe("MFLClub", () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8084);
    addressMap = await MFLClubTestsUtils.deployMFLClubContract("AliceAdminAccount");
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe("totalSupply", () => {
    test("should be able to get the totalSupply", async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: "mfl/players/get_players_total_supply.script",
      });
      expect(totalSupply).toBe(0);
    });
  });
});

import {emulator, getAccountAddress} from '@onflow/flow-js-testing';
import {MFLAdminTestsUtils} from './_utils/MFLAdminTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import adminClaim from './_transactions/check_admin_claim.tx';
import {GET_ROYALTY_ADDRESS} from './_scripts/get_royalty_address.script';
import {CREATE_ADMIN_ROOT_MALICIOUS} from './_transactions/create_admin_root_malicious.tx';
import {CREATE_ADMIN_ROOT_MALICIOUS_V2} from './_transactions/create_admin_root_malicious_v2.tx';
import {CREATE_ADMIN_ROOT_MALICIOUS_V3} from './_transactions/create_admin_root_malicious_v3.tx';
import {GET_ADMIN_CLAIM_MALICIOUS} from './_transactions/get_admin_claim_malicious.tx';
import {GET_ADMIN_CLAIM_MALICIOUS_V2} from './_transactions/get_admin_claim_malicious_v2.tx';
import {GET_ADMIN_CLAIM_MALICIOUS_V3} from './_transactions/get_admin_claim_malicious_v3.tx';
import {GET_ADMIN_CLAIM_MALICIOUS_V4} from './_transactions/get_admin_claim_malicious_v4.tx';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLAdmin', () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator();
    addressMap = await MFLAdminTestsUtils.deployMFLAdminContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('AdminRoot', () => {
    describe('createNewAdminRoot()', () => {
      test('should create an admin root', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [aliceAdminAccountAddress, bobAccountAddress];

        // execute
        const result = await testsUtils.shallPass({name: 'mfl/core/create_admin_root.tx', signers});

        // assert
        // bob must now be able to create another admin root
        await testsUtils.shallPass({
          name: 'mfl/core/create_admin_root.tx',
          signers: [bobAccountAddress, jackAccountAddress],
        });
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLAdmin)}.MFLAdmin.AdminRootCreated`,
            data: {by: aliceAdminAccountAddress},
          }),
        );
      });

      test('should throw an error when trying to create an admin root without the permission', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');

        // execute
        const err1 = await testsUtils.shallRevert({code: CREATE_ADMIN_ROOT_MALICIOUS, aliceAdminAccountAddress});
        const err2 = await testsUtils.shallRevert({code: CREATE_ADMIN_ROOT_MALICIOUS, bobAccountAddress});
        const err3 = await testsUtils.shallRevert({code: CREATE_ADMIN_ROOT_MALICIOUS_V2, args: [aliceAdminAccountAddress], bobAccountAddress});
        const err4 = await testsUtils.shallRevert({code: CREATE_ADMIN_ROOT_MALICIOUS_V3, args: [aliceAdminAccountAddress], bobAccountAddress});

        // assert
        expect(err1).toContain("cannot find variable in this scope: `AdminRoot`");
        expect(err2).toContain("cannot find variable in this scope: `AdminRoot`");
        expect(err3).toContain("function requires `Storage | BorrowValue` authorization, but reference is unauthorized");
        expect(err4).toContain("function requires `Storage | BorrowValue` authorization, but reference is unauthorized");
      });

      test('should panic when trying to create an admin root without being an admin root', async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [bobAccountAddress, jackAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/core/create_admin_root.tx', signers});

        // assert
        expect(error).toContain('Could not borrow AdminRoot ref');
      });
    });

    describe('setAdminProxyClaimCapability()', () => {
      test('should set a PlayerAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({
          name: 'mfl/players/give_player_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have a PlayerAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_PLAYER_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      });

      test('should set a PlayerAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({
          name: 'mfl/players/give_player_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have a PlayerAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_PLAYER_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      });

      test('should not be able to access a PlayerAdminClaim capability from another account', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({
          name: 'mfl/players/give_player_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const err1 = await testsUtils.shallRevert({code: GET_ADMIN_CLAIM_MALICIOUS, args: [bobAccountAddress], signers: [jackAccountAddress]});
        const err2 = await testsUtils.shallRevert({code: GET_ADMIN_CLAIM_MALICIOUS_V2, args: [bobAccountAddress], signers: [jackAccountAddress]});
        const err3 = await testsUtils.shallRevert({code: GET_ADMIN_CLAIM_MALICIOUS_V3, args: [bobAccountAddress], signers: [jackAccountAddress]});
        const err4 = await testsUtils.shallRevert({code: GET_ADMIN_CLAIM_MALICIOUS_V4, args: [bobAccountAddress], signers: [jackAccountAddress]});

        // assert
        expect(err1).toContain("Could not borrow admin proxy reference");
        expect(err2).toContain("cannot access `getClaimCapability`: function requires `AdminProxyAction` authorization, but reference is unauthorized");
        expect(err3).toContain("cannot access `claimsCapabilities`: field requires `self` authorization");
        expect(err4).toContain("cannot access `getControllers`: function requires `Capabilities | StorageCapabilities | GetStorageCapabilityController` authorization, but reference is unauthorized");
      });

      test('should set a PackAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/give_pack_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have a PackAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_PACK_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      });

      test('should set a PackTemplateAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/give_pack_template_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have a PackTemplateAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_PACK_TEMPLATE_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      });

      test('should set a ClubAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({
          name: 'mfl/clubs/give_club_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have a ClubAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_CLUB_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      });

      test('should set a SquadAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({
          name: 'mfl/clubs/squads/give_squad_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have a SquadAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_SQUAD_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      });
    });

    describe('revoke claim capability', () => {
      test('should revoke a PlayerAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        const result = await testsUtils.shallPass({
          name: 'mfl/players/give_player_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        await testsUtils.shallPass({
          name: 'mfl/core/delete_all_capabilities_by_path.tx',
          args: ["/storage/MFLPlayerAdmin"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should not have a PlayerAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_PLAYER_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow PlayerAdminClaim');
      });

      test('should revoke a PackAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({
          name: 'mfl/packs/give_pack_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        await testsUtils.shallPass({
          name: 'mfl/core/delete_all_capabilities_by_path.tx',
          args: ["/storage/MFLPackAdmin"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should not have a PackAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_PACK_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow PackAdminClaim');
      });

      test('should revoke a PackTemplateAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({
          name: 'mfl/packs/give_pack_template_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        await testsUtils.shallPass({
          name: 'mfl/core/delete_all_capabilities_by_path.tx',
          args: ["/storage/MFLPackTemplateAdmin"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should not have a PackTemplateAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_PACK_TEMPLATE_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow PackTemplateAdminClaim');
      });

      test('should revoke a ClubAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({
          name: 'mfl/clubs/give_club_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        await testsUtils.shallPass({
          name: 'mfl/core/delete_all_capabilities_by_path.tx',
          args: ["/storage/MFLClubAdmin"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should not have a ClubAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_CLUB_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow ClubAdminClaim');
      });

      test('should revoke a SquadAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({
          name: 'mfl/clubs/squads/give_squad_admin_claim.tx',
          args: [bobAccountAddress],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        await testsUtils.shallPass({
          name: 'mfl/core/delete_all_capabilities_by_path.tx',
          args: ["/storage/MFLSquadAdmin"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should not have a SquaddminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_SQUAD_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow SquadAdminClaim');
      });
    });
  });

  describe('AdminProxy', () => {
    describe('createAdminProxy()', () => {
      test('should create an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');

        // execute
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [aliceAdminAccountAddress]});

        // assert
        const adminProxyExists = await testsUtils.executeValidScript({
          code: `
            import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"

            access(all)
            fun main(address: Address): Bool {
              return getAccount(address).capabilities.get<&MFLAdmin.AdminProxy>(MFLAdmin.AdminProxyPublicPath).check()
            }
          `,
          args: [aliceAdminAccountAddress],
        });

        expect(adminProxyExists).toBe(true);
      });
    });
  });

  describe('royaltyAddress', () => {
    test('should get the royalty address', async () => {
      // prepare

      // execute
      const royaltyAddress = await testsUtils.executeValidScript({
        code: GET_ROYALTY_ADDRESS,
      });

      // assert
      expect(royaltyAddress).toEqual('0xa654669bd96b2014');
    });
  });
});

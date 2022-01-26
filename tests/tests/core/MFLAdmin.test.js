import { emulator, getAccountAddress } from 'flow-js-testing';
import { MFLAdminTestsUtils } from './_utils/MFLAdminTests.utils';
import { testsUtils } from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import adminClaim from './_transactions/check_admin_claim.tx';
expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLAdmin', () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8083);
    addressMap = await MFLAdminTestsUtils.deployMFLAdminContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('AdminRoot', () => {

    describe('createNewAdminRoot', () => {
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
        await testsUtils.shallPass({name: 'mfl/core/create_admin_root.tx', signers: [bobAccountAddress, jackAccountAddress]});
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLDrop)}.MFLAdmin.AdminRootCreated`,
          data: {by: aliceAdminAccountAddress}
        }));
      })

      test('should panic when trying to create an admin root without being an admin root', async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [bobAccountAddress, jackAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/core/create_admin_root.tx', signers});

        // assert
        expect(error).toContain('Could not borrow AdminRoot ref');
      })
    });

    describe('setAdminProxyClaimCapability', () => {
      test('should set a PlayerAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-playerAdminClaim`
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({name: 'mfl/players/give_player_admin_claim.tx', args: [bobAccountAddress, privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        // Bob should have a PlayerAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_PLAYER_ADMIN_CLAIM,
          signers: [bobAccountAddress]
        });
      })

      test('should set a DropAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-dropAdminClaim`
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({name: 'mfl/drops/give_drop_admin_claim.tx', args: [bobAccountAddress, privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        // Bob should have a DropAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_DROP_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      })

      test('should set a PackTemplateAdminClaim capability in an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-packTemplateAdminClaim`
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});

        // execute
        await testsUtils.shallPass({name: 'mfl/packs/give_pack_template_admin_claim.tx', args: [bobAccountAddress, privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        // Bob should have a PackTemplateAdminClaim Capability in his AdminProxy
        await testsUtils.shallPass({
          code: adminClaim.CHECK_PACK_TEMPLATE_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
      })

      test('should revoke a PlayerAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-playerAdminClaim`
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/players/give_player_admin_claim.tx', args: [bobAccountAddress, privatePath], signers: [aliceAdminAccountAddress]})

        // execute
        await testsUtils.shallPass({name: 'mfl/players/revoke_player_admin_claim.tx', args: [privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        // Bob should not have a PlayerAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_PLAYER_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow PlayerAdminClaim');
      })

      test('should revoke a DropAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-dropAdminClaim`
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/give_drop_admin_claim.tx', args: [bobAccountAddress, privatePath], signers: [aliceAdminAccountAddress]})

        // execute
        await testsUtils.shallPass({name: 'mfl/drops/revoke_drop_admin_claim.tx', args: [privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        // Bob should not have a DropAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_DROP_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow DropAdminClaim');
      })

      test('should revoke a PackTemplateAdminClaim capability', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-packTemplateAdminClaim`
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/packs/give_pack_template_admin_claim.tx', args: [bobAccountAddress, privatePath], signers: [aliceAdminAccountAddress]})

        // execute
        await testsUtils.shallPass({name: 'mfl/packs/revoke_pack_template_admin_claim.tx', args: [privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        // Bob should not have a PackTemplateAdminClaim Capability in his AdminProxy
        const error = await testsUtils.shallRevert({
          code: adminClaim.CHECK_PACK_TEMPLATE_ADMIN_CLAIM,
          signers: [bobAccountAddress],
        });
        expect(error).toContain('Could not borrow PackTemplateAdminClaim');
      })

      test('should panic if revoke capability path does not exist', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const privatePath = `/private/${bobAccountAddress}-playerAdminClaim`

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/players/revoke_player_admin_claim.tx', args: [privatePath], signers: [aliceAdminAccountAddress]})

        //assert
        expect(error).toContain('Capability path does not exist');
      })
    })
  });

  describe('AdminProxy', () => {
    describe('createAdminProxy', () => {
      test('should create an admin proxy', async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');

        // execute
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [aliceAdminAccountAddress]});

        //assert
        const adminProxyExists = await testsUtils.executeValidScript({
          code: `
            import MFLAdmin from "../../../../contracts/core/MFLAdmin.cdc"

            pub fun main(address: Address,): Bool {
              return getAccount(address).getCapability<&{MFLAdmin.AdminProxyPublic}>(MFLAdmin.AdminProxyPublicPath).check()
            }
          `,
          args: [aliceAdminAccountAddress],
        });
        expect(adminProxyExists).toBe(true)
      })
    })
  })
});

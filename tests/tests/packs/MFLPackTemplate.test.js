import { emulator, getAccountAddress } from 'flow-js-testing';
import { MFLPackTemplateTestsUtils } from './_utils/MFLPackTemplateTests.utils';
import { testsUtils } from '../_utils/tests.utils';
import * as matchers from 'jest-extended';

expect.extend(matchers);
jest.setTimeout(10000);

describe('MFLPackTemplate', () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8082);
    addressMap = await MFLPackTemplateTestsUtils.deployMFLPackTemplateContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('PackTemplateAdmin', () => {
    const args = ['Common', 'This is a common pack template', 25000, 'http://img1-url'];

    describe('createPackTemplate()', () => {
      test('should create a pack template', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];

        // execute
        const result = await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args, signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(
            addressMap.MFLPackTemplate
          )}.MFLPackTemplate.Created`,
          data: { id: 1 },
        }));
        const packTemplateData = await testsUtils.executeValidScript({name: 'mfl/packs/get_pack_template.script', args: [1]});
        expect(packTemplateData).toEqual({
          id: 1,
          name: 'Common',
          description: 'This is a common pack template',
          maxSupply: 25000,
          currentSupply: 0,
          startingIndex: 0,
          isOpenable: false,
          imageUrl: 'http://img1-url',
        });
      });
    });

    describe('allowToOpenPacks()', () => {
      test('should update isOpenable to true', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args, signers});

        // execute
        const result = await testsUtils.shallPass({name: 'mfl/packs/set_allow_to_open_packs.tx', args: [1], signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPackTemplate)}.MFLPackTemplate.AllowToOpenPacks`,
          data: {id: 1}
        }));
        const packTemplate = await testsUtils.executeValidScript({name: 'mfl/packs/get_pack_template.script', args: [1]});
        expect(packTemplate.isOpenable).toBe(true);
      });
    });

    describe('createPackTemplateAdmin()', () => {
      test('should create a packTemplate admin', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [aliceAdminAccountAddress, bobAccountAddress];

        // execute
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template_admin.tx', signers});

        // assert
        // bob must now be able to create another pack template admin
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template_admin.tx', signers: [bobAccountAddress, jackAccountAddress]});
      });

      test('should panic when trying to create a packTemplate admin with a non admin account', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [bobAccountAddress, jackAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/packs/create_pack_template_admin.tx', signers});

        // assert
        expect(error).toContain('Could not borrow packTemplate admin ref');
      });
    });
  });

  describe('PackTemplate', () => {

    const args1 = ['Common', 'This is a common pack template', 25000, 'http://img1-url'];
    const args2 = ['Rare', 'This is a rare pack template', 11050, 'http://img2-url'];

    describe('getPackTemplateIDs()', () => {
      test('should get ids', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args1, signers});
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args2, signers});

        // execute
        const packTemplateIds = await testsUtils.executeValidScript({name: 'mfl/packs/get_pack_template_ids.script', args: []});
        
        // assert
        expect(packTemplateIds).toEqual(expect.arrayContaining([1, 2]));
      })
    })

    describe('getPackTemplates()', () => {
      test('should get all packTemplates data', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args1, signers});
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args2, signers});

        // execute
        const packTemplates= await testsUtils.executeValidScript({name: 'mfl/packs/get_pack_templates.script', args: []});
        
        // assert
        expect(packTemplates).toEqual([
          {
            id: 1,
            name: 'Common',
            description: 'This is a common pack template',
            maxSupply: 25000,
            currentSupply: 0,
            startingIndex: 0,
            isOpenable: false,
            imageUrl: 'http://img1-url'
          },
          {
            id: 2,
            name: 'Rare',
            description: 'This is a rare pack template',
            maxSupply: 11050,
            currentSupply: 0,
            startingIndex: 0,
            isOpenable: false,
            imageUrl: 'http://img2-url'
          }
        ]);
      })
    })

    describe('getPackTemplate()', () => {
      test('should get a specific packTemplate data', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args1, signers});
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args2, signers});

        // execute
        const packTemplates= await testsUtils.executeValidScript({name: 'mfl/packs/get_pack_template.script', args: [2]});
        
        // assert
        expect(packTemplates).toEqual({
          id: 2,
          name: 'Rare',
          description: 'This is a rare pack template',
          maxSupply: 11050,
          currentSupply: 0,
          startingIndex: 0,
          isOpenable: false,
          imageUrl: 'http://img2-url'
        });
      })

      test('should return nil if packTemplate id does not exist', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: args1, signers});

        // execute
        const packTemplates= await testsUtils.executeValidScript({name: 'mfl/packs/get_pack_template.script', args: [2]});
        
        // assert
        expect(packTemplates).toEqual(null)
      })

    })
  })
});

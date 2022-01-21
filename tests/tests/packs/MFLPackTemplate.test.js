import {emulator, getAccountAddress} from 'flow-js-testing';
import {MFLPackTemplateTestsUtils} from './_utils/MFLPackTemplateTests.utils';
import {testsUtils} from '../_utils/tests.utils';
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

    const args = ["Common", "This is a common pack template", 25000, "http://img1-url"];

    describe('createPackTemplate', () => {
      test('should create a pack template', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        
        // execute
        const result = await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args, signers});
       
        // assert
        expect(result.status).toBe(4);
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPackTemplate)}.MFLPackTemplate.Created`,
          data: {id: 1}
        }));
        const packTemplateData = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [1]
        });
        expect(packTemplateData).toEqual(
          {
            id: 1,
            name: 'Common',
            description: 'This is a common pack template',
            maxSupply: 25000,
            currentSupply: 0,
            startingIndex: 0,
            isOpenable: false,
            imageUrl: 'http://img1-url'
          }
        )
      });
    });

    describe('allowToOpenPacks', () => {
      test('should update isOpenable to true', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        
        // execute
       
        // assert
       
      });
    });

    describe('createPackTemplateAdmin', () => {
      test('should create a packTemplate admin', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [aliceAdminAccountAddress, bobAccountAddress];

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template_admin.tx',
          signers,
        });

        // assert
        // bob must now be able to create another pack template admin
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template_admin.tx',
          signers: [bobAccountAddress, jackAccountAddress],
        });
      })

      test('should panic when trying to create a packTemplate admin with a non admin account', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [bobAccountAddress, jackAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/packs/create_pack_template_admin.tx',
          signers,
        });

        // assert
        expect(error).toContain('Could not borrow packTemplate admin ref');
      })
    })

    
  });

});
 
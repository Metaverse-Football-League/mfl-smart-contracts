import {emulator, getAccountAddress} from 'flow-js-testing';
import {MFLPackTemplateTestsUtils} from './_utils/MFLPackTemplateTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import {MFLPackTestsUtils} from './_utils/MFLPackTests.utils';
import _ from 'lodash';

expect.extend(matchers);
jest.setTimeout(40000);

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
    
    const args = {
      name: 'Base Pack',
      description: 'This is a Base pack template',
      maxSupply: 25000,
      imageUrl: 'http://img1-url',
      type: 'BASE',
      slotsNbr: 2,
      slotsType: ['common', 'uncommon'],
      slotsChances: [
        {
          common: '93.8',
          uncommon: '5',
          rare: '1',
          legendary: '0.2'
        },
        {
          common: '0',
          uncommon: '90',
          rare: '9.5',
          legendary: '0.5'
        },
      ],
      slotsCount: [2,1]
    };

    const argsTx = [
      args.name,
      args.description,
      args.maxSupply,
      args.imageUrl,
      args.type,
      args.slotsNbr,
      args.slotsType,
      args.slotsChances,
      args.slotsCount
    ]

    describe('createPackTemplate()', () => {
      test('should create a pack template', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: argsTx,
          signers
        });

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(
            addressMap.MFLPackTemplate,
          )}.MFLPackTemplate.Created`,
          data: {id: 1},
        }));
        const packTemplateData = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [1],
        });
        expect(packTemplateData).toEqual({
          id: 1,
          name: args.name,
          description: args.description,
          maxSupply: args.maxSupply,
          currentSupply: 0,
          startingIndex: 0,
          isOpenable: false,
          imageUrl: args.imageUrl,
          type: args.type,
          slots:  [...Array(args.slotsNbr)].map((_, i) => {
            return {
              type: args.slotsType[i],
              chances: args.slotsChances[i],
              count: args.slotsCount[i]
            }
          })
        });
      });
    });

    describe('allowToOpenPacks()', () => {
      test('should update isOpenable to true', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: argsTx,
          signers
        });

        // execute
        const result = await testsUtils.shallPass({name: 'mfl/packs/set_allow_to_open_packs.tx', args: [1], signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPackTemplate)}.MFLPackTemplate.AllowToOpenPacks`,
          data: {id: 1},
        }));
        const packTemplate = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [1],
        });
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
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template_admin.tx',
          signers: [bobAccountAddress, jackAccountAddress],
        });
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
    
    const args1 = {
      name: 'Base Pack',
      description: 'This is a Base pack template',
      maxSupply: 25000,
      imageUrl: 'http://img1-url',
      type: 'BASE',
      slotsNbr: 2,
      slotsType: ['common', 'uncommon'],
      slotsChances: [
        {
          common: '93.8',
          uncommon: '5',
          rare: '1',
          legendary: '0.2'
        },
        {
          common: '0',
          uncommon: '90',
          rare: '9.5',
          legendary: '0.5'
        },
      ],
      slotsCount: [2,1]
    };

    const args2 = {
      name: 'Rare Pack',
      description: 'This is a Rare pack template',
      maxSupply: 11050,
      imageUrl: 'http://img2-url',
      type: 'RARE',
      slotsNbr: 3,
      slotsType: ['common', 'uncommon', 'rare'],
      slotsChances: [
        {
          common: '93.8',
          uncommon: '5',
          rare: '1',
          legendary: '0.2'
        },
        {
          common: '0',
          uncommon: '90',
          rare: '9.5',
          legendary: '0.5'
        },
        {
          common: '0',
          uncommon: '0',
          rare: '98',
          legendary: '2'
        }
      ],
      slotsCount: [3,1,1]
    };

    const args1Tx = [
      args1.name,
      args1.description,
      args1.maxSupply,
      args1.imageUrl,
      args1.type,
      args1.slotsNbr,
      args1.slotsType,
      args1.slotsChances,
      args1.slotsCount
    ];
    const args2Tx = [
      args2.name,
      args2.description,
      args2.maxSupply,
      args2.imageUrl,
      args2.type,
      args2.slotsNbr,
      args2.slotsType,
      args2.slotsChances,
      args2.slotsCount
    ]

    describe('getPackTemplateIDs()', () => {
      test('should get ids', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args1Tx,
          signers
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args2Tx,
          signers
        });

        // execute
        const packTemplateIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template_ids.script',
          args: [],
        });

        // assert
        expect(packTemplateIds).toHaveLength(2);
        expect(packTemplateIds).toEqual(expect.arrayContaining([1, 2]));
      });
    });

    describe('getPackTemplates()', () => {
      test('should get all packTemplates data', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args1Tx,
          signers
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args2Tx,
          signers
        });

        // execute
        const packTemplates = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_templates.script',
          args: [],
        });

        // assert
        expect(packTemplates).toHaveLength(2);
        expect(packTemplates).toEqual(expect.arrayContaining([
          {
            id: 1,
            name: args1.name,
            description: args1.description,
            maxSupply: args1.maxSupply,
            currentSupply: 0,
            startingIndex: 0,
            isOpenable: false,
            imageUrl: args1.imageUrl,
            type: args1.type,
            slots:  [...Array(args1.slotsNbr)].map((_, i) => {
              return {
                type: args1.slotsType[i],
                chances: args1.slotsChances[i],
                count: args1.slotsCount[i]
              }
            })
          },
          {
            id: 2,
            name: args2.name,
            description: args2.description,
            maxSupply: args2.maxSupply,
            currentSupply: 0,
            startingIndex: 0,
            isOpenable: false,
            imageUrl: args2.imageUrl,
            type: args2.type,
            slots:  [...Array(args2.slotsNbr)].map((_, i) => {
              return {
                type: args2.slotsType[i],
                chances: args2.slotsChances[i],
                count: args2.slotsCount[i]
              }
            })
          }
        ]));
      });
    });

    describe('getPackTemplate()', () => {
      test('should get a specific packTemplate data', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args1Tx,
          signers
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args2Tx,
          signers
        });

        // execute
        const packTemplate = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [2],
        });

        // assert
        expect(packTemplate).toEqual({
          id: 2,
          name: args2.name,
          description: args2.description,
          maxSupply: args2.maxSupply,
          currentSupply: 0,
          startingIndex: 0,
          isOpenable: false,
          imageUrl: args2.imageUrl,
          type: args2.type,
          slots:  [...Array(args2.slotsNbr)].map((_, i) => {
            return {
              type: args2.slotsType[i],
              chances: args2.slotsChances[i],
              count: args2.slotsCount[i]
            }
          })
        });
      });

      test('should return nil if packTemplate id does not exist', async () => {
        // prepare
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_template.tx',
          args: args1Tx,
          signers
        });

        // execute
        const packTemplate = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [2],
        });

        // assert
        expect(packTemplate).toEqual(null);
      });
    });

    describe('startingIndex', () => {
      test('should increase the starting index when purchasing pack', async () => {
        // prepare
        const packTemplateSupply = 10;
        await MFLPackTestsUtils.deployMFLPackContract('AliceAdminAccount');
        await MFLPackTestsUtils.initPackTemplateAndDrop(
          'AliceAdminAccount', 'AliceAdminAccount',
          [args1.name, args1.description, packTemplateSupply, args1.imageUrl, args1.type, args1.slotsNbr, args1.slotsType, args1.slotsChances, args1.slotsCount],
          ['Drop name', '19,99', 1, 20],
        );
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const aliceAddressSumValue = _
          .chunk(testsUtils.sansPrefix(aliceAdminAccountAddress), 4)
          .map((addressParts) => addressParts.join(''))
          .map((addressPart) => parseInt(addressPart, 16))
          .reduce((sum, x) => sum + x);
        const aliceExpectedIncrease = aliceAddressSumValue % 500;

        const bobAccountAddress = await getAccountAddress('BobAccount');
        const bobAddressSumValue = _
          .chunk(testsUtils.sansPrefix(bobAccountAddress), 4)
          .map((addressParts) => addressParts.join(''))
          .map((addressPart) => parseInt(addressPart, 16))
          .reduce((sum, x) => sum + x);
        const bobExpectedIncrease = bobAddressSumValue % 500;

        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '40.00');

        // execute
        await testsUtils.shallPass({
          name: 'mfl/drops/purchase.tx',
          args: [1, 1, '19,99'],
          signers: [aliceAdminAccountAddress],
        });
        let packTemplate = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [1],
        });
        const startingIndexAfterFirstBuy = packTemplate.startingIndex;
        await testsUtils.shallPass({
          name: 'mfl/drops/purchase.tx',
          args: [1, 2, '39,98'],
          signers: [bobAccountAddress],
        });
        packTemplate = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: [1],
        });

        // assert
        const expectedStartingIndexAfterFirstBuy = aliceExpectedIncrease % packTemplateSupply;
        expect(startingIndexAfterFirstBuy).toEqual(expectedStartingIndexAfterFirstBuy);
        expect(startingIndexAfterFirstBuy).toBeGreaterThanOrEqual(0);
        expect(startingIndexAfterFirstBuy).toBeLessThan(packTemplateSupply);
        const expectedStartingIndexAfterBobPurchase = (startingIndexAfterFirstBuy + bobExpectedIncrease) % packTemplateSupply;
        expect(packTemplate.startingIndex).toEqual(expectedStartingIndexAfterBobPurchase);
        expect(packTemplate.startingIndex).toBeGreaterThanOrEqual(0);
        expect(packTemplate.startingIndex).toBeLessThan(packTemplateSupply);
      });
    });
  });
});

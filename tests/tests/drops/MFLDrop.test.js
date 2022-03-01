import {emulator, getAccountAddress} from 'flow-js-testing';
import {MFLDropTestsUtils} from './_utils/MFLDropTests.utils';
import {MFLPackTemplateTestsUtils} from '../packs/_utils/MFLPackTemplateTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLDrop', () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8081);
    addressMap = await MFLDropTestsUtils.deployMFLDropContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('DropAdmin', () => {

    const argsDrop = {
      name: "Drop name",
      price: "9.99",
      packTemplateID: 1,
      maxTokensPerAddress: 10
    };
    const argsDropTx = [
      argsDrop.name,
      argsDrop.price,
      argsDrop.packTemplateID,
      argsDrop.maxTokensPerAddress
    ];

    const argsPackTemplate = {
      name: 'Base Pack',
      description: 'This is a Base pack template',
      maxSupply: 10000,
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

    const argsPackTemplateTx = [
      argsPackTemplate.name,
      argsPackTemplate.description,
      argsPackTemplate.maxSupply,
      argsPackTemplate.imageUrl,
      argsPackTemplate.type,
      argsPackTemplate.slotsNbr,
      argsPackTemplate.slotsType,
      argsPackTemplate.slotsChances,
      argsPackTemplate.slotsCount
    ];

    describe('createDrop()', () => {
      test('should create a drop', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});

        // execute
        const result = await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLDrop)}.MFLDrop.Created`,
          data: {id: 1}
        }));
        const dropData = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drop.script',
          args: [1]
        });
        expect(dropData).toEqual({
          id: 1,
          name: argsDrop.name,
          price: parseFloat(argsDrop.price).toFixed(8).toString(),
          status: 0,
          packTemplateID: argsDrop.packTemplateID,
          maxTokensPerAddress: argsDrop.maxTokensPerAddress,
          minters: {},
          whitelistedAddresses: {}
        })
        const ownerVault = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_owner_vault.script',
        });
        expect(ownerVault).toBe(null)
      });

      test('should panic when trying to create a drop with a non existing packTemplate', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // assert
        expect(error).toContain('Pack template id does not exist');
      });

    });

    describe('setOwnerVault()', () => {
      test('should set the ownerVault', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // execute
        await testsUtils.shallPass({name: 'mfl/drops/set_owner_vault.tx', args: [], signers});

        // assert
        const ownerVault = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_owner_vault.script',
        });
        expect(ownerVault).toEqual(expect.objectContaining({
          address: aliceAdminAccountAddress,
        }));
      });

    });

    describe('setStatus()', () => {
      test('should update drop status to opened_whitelist', async () => {

        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // execute
        let result = await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_whitelist.tx', args: [1], signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLDrop)}.MFLDrop.StatusUpdated`,
          data: {status: 1}
        }));
        const dropsStatuses = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drops_statuses.script',
        });
        expect(dropsStatuses).toEqual({
          '1': {rawValue: 1}
        });
      });

      test('should update drop status to opened_all', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // execute
        let result = await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLDrop)}.MFLDrop.StatusUpdated`,
          data: {status: 2}
        }));
        const dropsStatuses = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drops_statuses.script',
        });
        expect(dropsStatuses).toEqual({
          '1': {rawValue: 2}
        });
      });

      test('should update drop status to closed', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers});

        // execute
        let result = await testsUtils.shallPass({name: 'mfl/drops/set_status_closed.tx', args: [1], signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLDrop)}.MFLDrop.StatusUpdated`,
          data: {status: 0}
        }));
        const dropsStatuses = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drops_statuses.script',
        });
        expect(dropsStatuses).toEqual({
          '1': {rawValue: 0}
        });
      });

    });

    describe('setWhitelistedAddresses()', () => {
      test('should set whitelistedAddresses', async () => {

        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        const whitelistedAddresses = {"0x0000000000000001": 1, "0x0000000000000002": 2, "0x0000000000000003": 3};
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // execute
        const result = await testsUtils.shallPass({name: 'mfl/drops/set_whitelisted_addresses.tx', args: [1,  whitelistedAddresses], signers});

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLDrop)}.MFLDrop.SetWhitelistedAddresses`,
          data: {addresses: whitelistedAddresses}
        }));
        const dropData = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drop.script',
          args: [1]
        });
        expect(dropData.whitelistedAddresses).toEqual(whitelistedAddresses);
      });

      test('should panic when trying to set whitelistedAddresses if number of tokens GT maxTokensPerAddress', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        const whitelistedAddresses = {"0x0000000000000001": 1, "0x0000000000000002": 20, "0x0000000000000003": 3};
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/set_whitelisted_addresses.tx', args: [1,  whitelistedAddresses], signers});

        // assert
        expect(error).toContain('Nb must be smaller or equal to maxTokensPerAddress');
      });
    });

    describe('setMaxTokensPerAddress()', () => {
      test('should set max tokens per address', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        const maxTokensPerAddress = 42;
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplateTx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDropTx, signers});

        // execute
        await testsUtils.shallPass({name: 'mfl/drops/set_max_tokens_per_address.tx', args: [1, maxTokensPerAddress], signers});

        // assert
        const dropData = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drop.script',
          args: [1]
        });
        expect(dropData.maxTokensPerAddress).toEqual(maxTokensPerAddress);
      });
    });

    describe('createDropAdmin()', () => {
      test('should create a drop admin', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [aliceAdminAccountAddress, bobAccountAddress];

        // execute
        await testsUtils.shallPass({
          name: 'mfl/drops/create_drop_admin.tx',
          signers,
        });

        // assert
        // bob must now be able to create another drop admin
        await testsUtils.shallPass({
          name: 'mfl/drops/create_drop_admin.tx',
          signers: [bobAccountAddress, jackAccountAddress],
        });
      })

      test('should panic when trying to create a drop admin with a non admin account', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        const signers = [bobAccountAddress, jackAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/drops/create_drop_admin.tx',
          signers,
        });

        // assert
        expect(error).toContain('Could not borrow drop admin ref');
      })
    })
  });

  describe('Drop', () => {

    const argsDrop1 = {
      name: "Drop 1 name",
      price: "9.99",
      packTemplateID: 1,
      maxTokensPerAddress: 10
    };
    const argsDrop1Tx = [
      argsDrop1.name,
      argsDrop1.price,
      argsDrop1.packTemplateID,
      argsDrop1.maxTokensPerAddress
    ];

    const argsDrop2 = {
      name: "Drop 2 name",
      price: "29.00",
      packTemplateID: 2,
      maxTokensPerAddress: 3
    };
    const argsDrop2Tx = [
      argsDrop2.name,
      argsDrop2.price,
      argsDrop2.packTemplateID,
      argsDrop2.maxTokensPerAddress
    ];

    const argsPackTemplate1 = {
      name: 'Base Pack',
      description: 'This is a Base pack template',
      maxSupply: 10000,
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

    const argsPackTemplate1Tx = [
      argsPackTemplate1.name,
      argsPackTemplate1.description,
      argsPackTemplate1.maxSupply,
      argsPackTemplate1.imageUrl,
      argsPackTemplate1.type,
      argsPackTemplate1.slotsNbr,
      argsPackTemplate1.slotsType,
      argsPackTemplate1.slotsChances,
      argsPackTemplate1.slotsCount
    ];

    const argsPackTemplate2 = {
      name: 'Rare Pack',
      description: 'This is a Rare pack template',
      maxSupply: 99,
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

    const argsPackTemplate2Tx = [
      argsPackTemplate2.name,
      argsPackTemplate2.description,
      argsPackTemplate2.maxSupply,
      argsPackTemplate2.imageUrl,
      argsPackTemplate2.type,
      argsPackTemplate2.slotsNbr,
      argsPackTemplate2.slotsType,
      argsPackTemplate2.slotsChances,
      argsPackTemplate2.slotsCount
    ];

    describe('getDrops()', () => {
      test('should get all drops data', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers});
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate2Tx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop2Tx, signers});

        // execute
        const dropsData = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drops.script',
        });

        // assert
        expect(dropsData).toHaveLength(2);
        expect(dropsData).toEqual(expect.arrayContaining([
          {
            id: 1,
            name: argsDrop1.name,
            price: parseFloat(argsDrop1.price).toFixed(8).toString(),
            status: 0,
            packTemplateID: argsDrop1.packTemplateID,
            maxTokensPerAddress: argsDrop1.maxTokensPerAddress,
            minters: {},
            whitelistedAddresses: {}
          },
          {
            id: 2,
            name: argsDrop2.name,
            price: parseFloat(argsDrop2.price).toFixed(8).toString(),
            status: 0,
            packTemplateID: argsDrop2.packTemplateID,
            maxTokensPerAddress: argsDrop2.maxTokensPerAddress,
            minters: {},
            whitelistedAddresses: {}
          }
        ]));
      })
    })

    describe('getDrop()', () => {
      test('should get a specific drop data', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers});
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate2Tx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop2Tx, signers});

        // execute
        const dropData = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drop.script',
          args: [2]
        });

        // assert
        expect(dropData).toEqual(
          {
            id: 2,
            name: argsDrop2.name,
            price: parseFloat(argsDrop2.price).toFixed(8).toString(),
            status: 0,
            packTemplateID: argsDrop2.packTemplateID,
            maxTokensPerAddress: argsDrop2.maxTokensPerAddress,
            minters: {},
            whitelistedAddresses: {}
          }
        );
      })

      test('should return nil if drop id does not exist', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers});

        // execute
        const dropData = await testsUtils.executeValidScript({
          name: 'mfl/drops/get_drop.script',
          args: [2]
        });

        // assert
        expect(dropData).toEqual(null);
      })

    })

    describe('getDropsIDs()', () => {
      test('should get ids', async () => {
          // prepare
          await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
          await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
          const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
          const signers = [aliceAdminAccountAddress];
          await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers});
          await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers});
          await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate2Tx, signers});
          await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop2Tx, signers});

          // execute
          const dropsIds = await testsUtils.executeValidScript({
            name: 'mfl/drops/get_ids.script',
          });

          // assert
          expect(dropsIds).toHaveLength(2);
          expect(dropsIds).toEqual(expect.arrayContaining([1, 2]));
      })

    })

    describe('getDropsStatuses()', () => {
      test('should get all drops statuses', async () => {
          // prepare
          await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
          await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
          const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
          const signers = [aliceAdminAccountAddress];
          await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers});
          await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers});
          await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate2Tx, signers});
          await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop2Tx, signers});

          // execute
          const dropsStatuses = await testsUtils.executeValidScript({
            name: 'mfl/drops/get_drops_statuses.script',
          });

          // assert
          expect(dropsStatuses).toEqual({
            '1': {rawValue: 0},
            '2': {rawValue: 0}
          });
      })

    })

    describe('purchase()', () => {

      const price = '5.00';
      argsDrop1.price = price;
      argsDrop1Tx[1] = price;

      test('should create one pack in collection', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_owner_vault.tx', args: [], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        await testsUtils.shallPass({name: 'mfl/drops/purchase.tx', args: [1, 1, "5.00"], signers: [bobAccountAddress]});

        // assert
        const packIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress]
        });
        expect(packIds).toEqual([1]);
      })

      test('should return multiple packs in collection', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_owner_vault.tx', args: [], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        await testsUtils.shallPass({name: 'mfl/drops/purchase.tx', args: [1, 5, "25.00"], signers: [bobAccountAddress]});

        // assert
        const packIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress]
        });
        expect(packIds).toHaveLength(5);
        expect(packIds).toEqual(expect.arrayContaining([1, 2, 3, 4, 5]));
      })

      test('should panic if drop id does not exist', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [2, 5, "25.00"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Drop does not exist');
      })

      test('should panic if drop is closed', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 5, "25.00"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Drop is closed');
      })

      test('should panic if number of packs to purchase equal 0', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 0, "25.00"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Nb to mint must be greater than 0');
      })

      test('should panic if number of packs per address exceeded', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 11, "55.0"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Max tokens per address exceeded');
      })

      test('should panic if drop status is opened_whitelist and address is not whitelisted', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_whitelist.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 5, "25.0"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Not whitelisted');
      })

      test('should panic if drop status is opened_whitelist and whitelisted address exceeded the max number of packs', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        let  whitelistedAddresses = {}
        whitelistedAddresses[bobAccountAddress] = 4
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_whitelist.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_whitelisted_addresses.tx', args: [1, whitelistedAddresses], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 5, "25.0"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Max tokens exceeded for whitelist');
      })

      test('should panic if balance is not enough', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 5, "24.00"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Not enough balance');
      })

      test('should panic if owner vault is not set', async () => {
        // prepare
        await MFLDropTestsUtils.createDropAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPackTemplateTestsUtils.createPackTemplateAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop1Tx, signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [1], signers: [aliceAdminAccountAddress]});
        await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [bobAccountAddress] });
        await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [bobAccountAddress, "100.00"], signers: [aliceAdminAccountAddress]});

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/drops/purchase.tx', args: [1, 5, "25.00"], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain('Could not borrow reference to owner vault');
      })

    })
  });

});

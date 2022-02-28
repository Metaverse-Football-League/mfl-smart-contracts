import {emulator, getAccountAddress} from 'flow-js-testing';
import {MFLPackTestsUtils} from './_utils/MFLPackTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import {WITHDRAW_PACK} from './_transactions/withdaw_pack.tx';
import {BATCH_WITHDRAW_PACK} from './_transactions/batch_withdaw_pack.tx';
import {BORROW_NFT} from './_scripts/borrow_nft.script';
import {BORROW_VIEW_RESOLVER} from './_scripts/borrow_view_resolver.script';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLPack', () => {
  let addressMap = null;

  const argsDrop = {
    name: "Drop name",
    price: "19.99",
    packTemplateID: 1,
    maxTokensPerAddress: 20
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
    maxSupply: 8500,
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

  beforeEach(async () => {
    await testsUtils.initEmulator(8084);
    addressMap = await MFLPackTestsUtils.deployMFLPackContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('totalSupply', () => {
    test('should be able to get the totalSupply', async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: 'mfl/packs/get_packs_total_supply.script',
      });
      expect(totalSupply).toBe(0);
    });
  });

  describe('Collection', () => {
    describe('withdraw() / deposit()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, jackAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);
        await MFLPackTestsUtils.purchase(jackAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({
          code: WITHDRAW_PACK,
          args: [jackAccountAddress, 1],
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 1, from: bobAccountAddress},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
          data: {id: 1, to: jackAccountAddress},
        }));
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        const jackPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [jackAccountAddress],
        });
        // Bob should have 0 pack
        expect(bobPackIds).toEqual([]);
        // Jack should have 2 packs
        expect(jackPackIds).toHaveLength(2);
        expect(jackPackIds).toEqual(expect.arrayContaining([1, 2]));
      });

      test('should panic when trying to withdraw a NFT which is not in the collection', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const error = await testsUtils.shallRevert({
          code: WITHDRAW_PACK,
          args: [bobAccountAddress, 42],
          signers: [bobAccountAddress],
        });

        // assert
        expect(error).toContain('missing NFT');
      });
    });

    describe('batchWithdraw()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, jackAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);
        await MFLPackTestsUtils.purchase(jackAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({
          code: BATCH_WITHDRAW_PACK,
          args: [jackAccountAddress, [1, 2]],
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(8);
        expect(result.events).toEqual(expect.arrayContaining([
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 1, from: bobAccountAddress},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 1, to: null},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 2, from: bobAccountAddress},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 2, to: null},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 2, from: null},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 2, to: jackAccountAddress},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 1, from: null},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 1, to: jackAccountAddress},
          }
        ]));
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        const jackPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [jackAccountAddress],
        });
        // Bob shoud have 0 pack
        expect(bobPackIds).toEqual([]);
        // Jack should have 4 packs
        expect(jackPackIds).toHaveLength(4);
        expect(jackPackIds).toEqual(expect.arrayContaining([1, 2, 3, 4]));
      });
    });

    describe('getIDs()', () => {
      test('should get the IDs in the collection', async () => {
        // prepare
        const argsPurchase = [1, 10, '199.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '200.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });

        // assert
        // Bob should have 10 packs
        expect(bobPackIds).toHaveLength(10);
        expect(bobPackIds).toEqual(expect.arrayContaining([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
      });
    });

    describe('borrowNFT()', () => {
      test('should borrow a NFT in the collection', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const pack = await testsUtils.executeValidScript({
          code: BORROW_NFT,
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(pack).toEqual({
          uuid: expect.toBeNumber(),
          id: 1,
          packTemplateMintIndex: 0,
          packTemplateID: 1,
        });
      });
    });

    describe('borrowViewResolver()', () => {
      test('should return a reference to a NFT as a MetadataViews.Resolver interface', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const pack = await testsUtils.executeValidScript({
          code: BORROW_VIEW_RESOLVER,
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(pack).toEqual({
          uuid: expect.toBeNumber(),
          id: 1,
          packTemplateMintIndex: 0,
          packTemplateID: 1,
        });
      });
    });

    describe('openPack()', () => {
      test('should burn a pack when opening it', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop(
          'AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx
        );
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, aliceAdminAccountAddress, '100.00');
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.purchase(aliceAdminAccountAddress, argsPurchase);
        await testsUtils.shallPass({
          name: 'mfl/packs/set_allow_to_open_packs.tx',
          args: [1],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/packs/open_pack.tx',
          args: [2],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        const packIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [aliceAdminAccountAddress],
        });
        expect(packIds).toEqual([1]);
        expect(result.events).toHaveLength(3);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 2, from: aliceAdminAccountAddress},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Opened`,
          data: {
            id: 2,
            packIndex: expect.toBeNumber(),
            packTemplateID: 1,
            from: aliceAdminAccountAddress,
          },
        }));
        expect(result.events[2]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Destroyed`,
          data: {id: 2},
        }));
      });

      test('should panic when opening a pack while the pack template is not openable', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop(
          'AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx,
        );
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, aliceAdminAccountAddress, '100.00');
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.purchase(aliceAdminAccountAddress, argsPurchase);

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/packs/open_pack.tx',
          args: [2],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain('PackTemplate is not openable');
      });
    });

    describe('destroy()', () => {
      test('should destroy a collection', async () => {
        // prepare
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({
          code: `
            import MFLPack from "../../../contracts/packs/MFLPack.cdc"
            
            transaction() {
            
                prepare(acct: AuthAccount) {
                    let collection <- acct.load<@MFLPack.Collection>(from: MFLPack.CollectionStoragePath)!
                    destroy collection
                }
            }
          `,
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events).toEqual(expect.arrayContaining([
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Destroyed`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 1},
          },
          {
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Destroyed`,
            transactionId: expect.toBeString(),
            transactionIndex: 1,
            eventIndex: expect.toBeNumber(),
            data: {id: 2},
          }
        ]));
        const error = await testsUtils.executeFailingScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        // Bob should no longer have a collection
        expect(error.message).toContain('Could not borrow the collection reference');
      });
    });

    describe('createEmptyCollection()', () => {
      test('should create an empty collection', async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress('BobAccount');

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });

        // assert
        // Bob should have a collection
        await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
      });
    });
  });

  describe('NFT', () => {

    const argsPurchase = [1, 1, '19.99'];

    describe('getViews()', () => {
      test('should get views types', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const viewsTypes = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_views_from_collection.script',
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(viewsTypes).toHaveLength(2);
        expect(viewsTypes).toEqual(expect.arrayContaining([
          `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
          `A.${testsUtils.sansPrefix(addressMap.MFLViews)}.MFLViews.PackDataViewV1`,
        ]));
      });
    });

    describe('resolveView()', () => {
      test('should resolve Display view for a specific pack', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const packDisplayView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_display_view_from_collection.script',
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(packDisplayView).toEqual(
          {
            name: argsPackTemplate.name,
            description: 'MFL Pack #1',
            thumbnail: argsPackTemplate.imageUrl,
            owner: bobAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
          },
        );
      });

      test('should resolve Display view for all packs', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const packsDisplayView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_packs_display_view_from_collection.script',
          args: [bobAccountAddress],
        });

        // assert
        expect(packsDisplayView).toHaveLength(2);
        expect(packsDisplayView).toEqual(expect.arrayContaining([
          {
            name: argsPackTemplate.name,
            description: 'MFL Pack #1',
            thumbnail: argsPackTemplate.imageUrl,
            owner: bobAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
          },
          {
            name: argsPackTemplate.name,
            description: 'MFL Pack #2',
            thumbnail: argsPackTemplate.imageUrl,
            owner: bobAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
          },
        ]));
      });

      test('should resolve PackData view for a specific pack', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const packDataView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_data_view_from_collection.script',
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(packDataView).toEqual(
          {
            id: 1,
            packTemplateMintIndex: 0,
            packTemplate: {
              id: 1,
              name: argsPackTemplate.name,
              description: argsPackTemplate.description,
              maxSupply: argsPackTemplate.maxSupply,
              currentSupply: 1,
              startingIndex: expect.toBeNumber(),
              isOpenable: false,
              imageUrl: argsPackTemplate.imageUrl,
              type: argsPackTemplate.type,
              slots:  [...Array(argsPackTemplate.slotsNbr)].map((_, i) => {
                return {
                  type: argsPackTemplate.slotsType[i],
                  chances: argsPackTemplate.slotsChances[i],
                  count: argsPackTemplate.slotsCount[i]
                }
              })
            },
          },
        );
      });

      test('should resolve PackData view for all packs', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        const argsPurchase = [1, 3, '59.97'];
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const packsDataView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_packs_data_view_from_collection.script',
          args: [bobAccountAddress],
        });

        // assert
        expect(packsDataView).toHaveLength(3);
        expect(packsDataView).toEqual(expect.arrayContaining([
          {
            id: 1,
            packTemplateMintIndex: 0,
            packTemplate: {
              id: 1,
              name: argsPackTemplate.name,
              description: argsPackTemplate.description,
              maxSupply: argsPackTemplate.maxSupply,
              currentSupply: 3,
              startingIndex: expect.toBeNumber(),
              isOpenable: false,
              imageUrl: argsPackTemplate.imageUrl,
              type: argsPackTemplate.type,
              slots:  [...Array(argsPackTemplate.slotsNbr)].map((_, i) => {
                return {
                  type: argsPackTemplate.slotsType[i],
                  chances: argsPackTemplate.slotsChances[i],
                  count: argsPackTemplate.slotsCount[i]
                }
              })
            },
          },
          {
            id: 2,
            packTemplateMintIndex: 1,
            packTemplate: {
              id: 1,
              name: argsPackTemplate.name,
              description: argsPackTemplate.description,
              maxSupply: argsPackTemplate.maxSupply,
              currentSupply: 3,
              startingIndex: expect.toBeNumber(),
              isOpenable: false,
              imageUrl: argsPackTemplate.imageUrl,
              type: argsPackTemplate.type,
              slots:  [...Array(argsPackTemplate.slotsNbr)].map((_, i) => {
                return {
                  type: argsPackTemplate.slotsType[i],
                  chances: argsPackTemplate.slotsChances[i],
                  count: argsPackTemplate.slotsCount[i]
                }
              })
            },
          },
          {
            id: 3,
            packTemplateMintIndex: 2,
            packTemplate: {
              id: 1,
              name: argsPackTemplate.name,
              description: argsPackTemplate.description,
              maxSupply: argsPackTemplate.maxSupply,
              currentSupply: 3,
              startingIndex: expect.toBeNumber(),
              isOpenable: false,
              imageUrl: argsPackTemplate.imageUrl,
              type: argsPackTemplate.type,
              slots:  [...Array(argsPackTemplate.slotsNbr)].map((_, i) => {
                return {
                  type: argsPackTemplate.slotsType[i],
                  chances: argsPackTemplate.slotsChances[i],
                  count: argsPackTemplate.slotsCount[i]
                }
              })
            },
          },
        ]));
      });
    });

    describe('destroy()', () => {
      test('should destroy the NFT', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx, argsDropTx);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/packs/destroy_pack.tx',
          args: [1],
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toPartiallyContain({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Destroyed`,
          data: {id: 1},
        });
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        // Bob should have 0 pack
        expect(bobPackIds).toEqual([]);
      });
    });
  });
});

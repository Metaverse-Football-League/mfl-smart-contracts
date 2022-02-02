import { emulator, getAccountAddress } from 'flow-js-testing';
import { MFLPackTestsUtils } from './_utils/MFLPackTests.utils';
import { testsUtils } from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import { WITHDRAW_PACK } from './_transactions/withdaw_pack.tx';
import { BATCH_WITHDRAW_PACK } from './_transactions/batch_withdaw_pack.tx';
import { BORROW_NFT } from './_scripts/borrow_nft.script';
import { BORROW_VIEW_RESOLVER } from './_scripts/borrow_view_resolver.script';

expect.extend(matchers);
jest.setTimeout(10000);

describe('MFLPack', () => {
  let addressMap = null;
  // argsDrop: [drop name, price, packTemplateId, maxTokensPerAddress]
  const argsDrop = ['Drop name', '19,99', 1, 20];
  // argsPackTemplate: [title, description, maxSupply, imageUrl]
  const argsPackTemplate = ['Common', 'This is a common pack', 8500, 'http://img1-url'];

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
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, jackAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);
        await MFLPackTestsUtils.purchase(jackAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({code: WITHDRAW_PACK, args: [jackAccountAddress, 1], signers: [bobAccountAddress]});

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 1, from: bobAccountAddress}
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
          data: {id: 1, to: jackAccountAddress}
        }));
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        const jackPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [jackAccountAddress],
        });
        // Bob shoud have 0 pack
        expect(bobPackIds).toEqual([])
        // Jack should have 2 packs
        expect(jackPackIds).toHaveLength(2);
        expect(jackPackIds).toEqual(expect.arrayContaining([1, 2]))
      })

      test('should panic when trying to withdraw a NFT which is not in the collection', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const error = await testsUtils.shallRevert({code: WITHDRAW_PACK, args: [bobAccountAddress, 42], signers: [bobAccountAddress]});

        // assert
        expect(error).toContain("missing NFT")
      })
    })

    describe('batchWithdraw()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, jackAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);
        await MFLPackTestsUtils.purchase(jackAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({code: BATCH_WITHDRAW_PACK, args: [jackAccountAddress, [1, 2]], signers: [bobAccountAddress]});

        // assert
        expect(result.events).toHaveLength(8);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 1, from: bobAccountAddress}
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
          data: {id: 1, to: null}
        }));
        expect(result.events[2]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 2, from: bobAccountAddress}
        }));
        expect(result.events[3]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
          data: {id: 2, to: null}
        }));
        expect(result.events[4]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 2, from: null}
        }));
        expect(result.events[5]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
          data: {id: 2, to: jackAccountAddress}
        }));
        expect(result.events[6]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Withdraw`,
          data: {id: 1, from: null}
        }));
        expect(result.events[7]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Deposit`,
          data: {id: 1, to: jackAccountAddress}
        }));
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        const jackPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [jackAccountAddress],
        });
        // Bob shoud have 0 pack
        expect(bobPackIds).toEqual([])
        // Jack should have 4 packs
        expect(jackPackIds).toHaveLength(4);
        expect(jackPackIds).toEqual(expect.arrayContaining([1, 2, 3, 4]))
      })
    })

    describe('getIDs()', () => {
      test('should get the IDs in the collection', async () => {
        // prepare
        const argsPurchase = [1, 10, '190.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
        expect(bobPackIds).toEqual(expect.arrayContaining([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
      })
    })

    describe('borrowNFT()', () => {
      test('should borrow a NFT in the collection', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
          packTemplateID: 1
        })
      })
    })

    describe('borrowViewResolver()', () => {
      test('should return a reference to a NFT as a MetadataViews.Resolver interface', async () => {
        // prepare
        const argsPurchase = [1, 1, '19.99'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
          packTemplateID: 1
        });
      });
    });

    describe('destroy()', () => {
      test('should destroy a collection', async () => {
        // prepare
        const argsPurchase = [1, 2, '39.98'];
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Destroyed`,
          data: {id: 1},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Destroyed`,
          data: {id: 2},
        }));
        const error = await testsUtils.executeFailingScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        // Bob should no longer have a collection
        expect(error.message).toContain("Could not borrow the collection reference")
      })
    })

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
      })
    })
  })

  describe('NFT', () => {
    
    const argsPurchase = [1, 1, '19.99'];

    describe('getViews()', () => {
      test('should get views types', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
        expect(viewsTypes).toEqual(expect.arrayContaining([
          `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
          `A.${testsUtils.sansPrefix(addressMap.MFLViews)}.MFLViews.PackDataViewV1`,
        ]));
      });
    });

    describe('resolveView()', () => {
      test('should resolve Display view for a specific pack', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
            name: 'Common',
            description: 'MFL Pack #1',
            thumbnail: 'http://img1-url',
            owner: bobAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
          }
        );
      });

      test('should resolve Display view for all packs', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
        expect(packsDisplayView).toEqual(expect.arrayContaining([
          {
            name: 'Common',
            description: 'MFL Pack #1',
            thumbnail: 'http://img1-url',
            owner: bobAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
          },
          {
            name: 'Common',
            description: 'MFL Pack #2',
            thumbnail: 'http://img1-url',
            owner: bobAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
          }
        ]));
      });

      test('should resolve PackData view for a specific pack', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
            packTemplateID: 1,
            packTemplateName: 'Common',
            packTemplateDescription: 'This is a common pack',
            packTemplateMaxSupply: 8500,
            packTemplateCurrentSupply: 1,
            packTemplateStartingIndex: 255,
            packTemplateIsOpenable: false,
            packTemplateImageUrl: 'http://img1-url'
          }
        );
      });

      test('should resolve PackData view for all packs', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
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
        expect(packsDataView).toEqual(expect.arrayContaining([
          {
            id: 1,
            packTemplateMintIndex: 0,
            packTemplateID: 1,
            packTemplateName: 'Common',
            packTemplateDescription: 'This is a common pack',
            packTemplateMaxSupply: 8500,
            packTemplateCurrentSupply: 3,
            packTemplateStartingIndex: 255,
            packTemplateIsOpenable: false,
            packTemplateImageUrl: 'http://img1-url'
          },
          {
            id: 3,
            packTemplateMintIndex: 2,
            packTemplateID: 1,
            packTemplateName: 'Common',
            packTemplateDescription: 'This is a common pack',
            packTemplateMaxSupply: 8500,
            packTemplateCurrentSupply: 3,
            packTemplateStartingIndex: 255,
            packTemplateIsOpenable: false,
            packTemplateImageUrl: 'http://img1-url'
          },
          {
            id: 2,
            packTemplateMintIndex: 1,
            packTemplateID: 1,
            packTemplateName: 'Common',
            packTemplateDescription: 'This is a common pack',
            packTemplateMaxSupply: 8500,
            packTemplateCurrentSupply: 3,
            packTemplateStartingIndex: 255,
            packTemplateIsOpenable: false,
            packTemplateImageUrl: 'http://img1-url'
          }
        ]));
      });
    });

    describe('destroy()', () => {
      test('should destroy the NFT', async () => {
        // prepare
        await MFLPackTestsUtils.initPackTemplateAndDrop('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplate, argsDrop);
        const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await MFLPackTestsUtils.setupAndTopupFusdAccount(aliceAdminAccountAddress, bobAccountAddress, '100.00');
        await MFLPackTestsUtils.purchase(bobAccountAddress, argsPurchase);

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/packs/destroy_pack.tx',
          args: [1],
          signers: [bobAccountAddress]
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
        expect(bobPackIds).toEqual([])
      });
    });
  });
});

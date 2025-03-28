import {emulator, getAccountAddress} from '@onflow/flow-js-testing';
import {MFLPackTestsUtils} from './_utils/MFLPackTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import {WITHDRAW_PACK} from './_transactions/withdaw_pack.tx';
import {BATCH_WITHDRAW_PACK} from './_transactions/batch_withdaw_pack.tx';
import {BORROW_NFT} from './_scripts/borrow_nft.script';
import {BORROW_VIEW_RESOLVER} from './_scripts/borrow_view_resolver.script';
import {GET_PACK_ROYALTIES_VIEW} from './_scripts/get_pack_royalties_view.script';
import {MFLClubTestsUtils} from '../clubs/_utils/MFLClubTests.utils';
import {WITHDRAW_CLUB_FROM_GIVEN_ADDRESS} from '../clubs/_transactions/withdraw_club_from_given_address_malicious.tx';
import {
  WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2
} from '../clubs/_transactions/withdraw_club_from_given_address_v2_malicious.tx';
import {
  BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS
} from '../clubs/_transactions/batch_withdraw_club_from_given_address_malicious.tx';
import {
  BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2
} from '../clubs/_transactions/batch_withdraw_club_from_given_address_malicious_v2.tx';
import {
  WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V3
} from '../clubs/_transactions/withdraw_club_from_given_address_v3_malicious.tx';
import {WITHDRAW_PACK_FROM_GIVEN_ADDRESS} from './_transactions/withdraw_pack_from_given_address_malicious.tx';
import {WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V2} from './_transactions/withdraw_pack_from_given_address_v2_malicious.tx';
import {
  BATCH_WITHDRAW_PACK_FROM_GIVEN_ADDRESS
} from './_transactions/batch_withdraw_pack_from_given_address_malicious.tx';
import {
  BATCH_WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V2
} from './_transactions/batch_withdraw_pack_from_given_address_malicious_v2.tx';
import {WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V3} from './_transactions/withdraw_pack_from_given_address_v3_malicious.tx';
import {OPEN_PACK_MALICIOUS} from '../clubs/_transactions/open_pack_malicious.tx';
import {OPEN_PACK_MALICIOUS_V2} from '../clubs/_transactions/open_pack_malicious_v2.tx';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLPack', () => {
  let addressMap = null;

  const argsPackTemplate = {
    name: 'Base Pack',
    description: 'This is a Base pack template',
    maxSupply: '8500',
    imageUrl: 'http://img1-url',
    type: 'BASE',
    slotsNbr: '2',
    slotsType: ['common', 'uncommon'],
    slotsChances: [
      {
        common: '93.8',
        uncommon: '5',
        rare: '1',
        legendary: '0.2',
      },
      {
        common: '0',
        uncommon: '90',
        rare: '9.5',
        legendary: '0.5',
      },
    ],
    slotsCount: ['2', '1'],
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
    argsPackTemplate.slotsCount,
  ];

  let aliceAdminAccountAddress = null;
  let bobAccountAddress = null;
  let jackAccountAddress = null;

  beforeEach(async () => {
    await testsUtils.initEmulator();
    addressMap = await MFLPackTestsUtils.deployMFLPackContract('AliceAdminAccount');
    // Create PackTemplate
    await MFLPackTestsUtils.initPackTemplate('AliceAdminAccount', 'AliceAdminAccount', argsPackTemplateTx);
    // Give Alice PackAdminClaim to mint Packs
    await MFLPackTestsUtils.createPackAdmin('AliceAdminAccount', 'AliceAdminAccount');
    // Store 3 accounts addresses
    aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
    bobAccountAddress = await getAccountAddress('BobAccount');
    jackAccountAddress = await getAccountAddress('JackAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('totalSupply', () => {
    test('should be able to get the totalSupply', async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: 'mfl/packs/get_packs_total_supply.script',
      });
      expect(totalSupply).toBe('0');
    });
  });

  describe('PackAdmin', () => {
    describe('batchMintPack()', () => {
      test('should mint 1 pack', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        const argsMint = ['1', bobAccountAddress, '1'];

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have 1 pack
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        expect(bobPackIds).toEqual(['1']);
      });

      test('should mint 5 packs', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        const argsMint = ['1', bobAccountAddress, '5'];

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // Bob should have 5 packs
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        expect(bobPackIds).toEqual(expect.arrayContaining(['1', '2', '3', '4', '5']));
      });

      test('should increase supply', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        const argsMint = ['1', bobAccountAddress, '5'];

        // execute
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        // supply should now be 5
        const packTemplate = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_template.script',
          args: ['1'],
        });
        expect(packTemplate.currentSupply).toEqual('5');
      });

      test('should panic if Pack Template does not exist', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        const argsMint = ['2', bobAccountAddress, '1'];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain('PackTemplate does not exist');
      });

      test('should panic if supply is exceeded', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        const argsMint = ['1', bobAccountAddress, '8501'];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain('Supply exceeded');
      });
    });

    describe('createPackAdmin()', () => {
      test('should create a Pack admin', async () => {
        // prepare
        const signers = [aliceAdminAccountAddress, bobAccountAddress];

        // execute
        await testsUtils.shallPass({name: 'mfl/packs/create_pack_admin.tx', signers});

        // assert
        // bob must now be able to create another Pack admin
        await testsUtils.shallPass({
          name: 'mfl/packs/create_pack_admin.tx',
          signers: [bobAccountAddress, jackAccountAddress],
        });
      });

      test('should panic when trying to create a Pack admin with a non admin account', async () => {
        // prepare
        const signers = [bobAccountAddress, jackAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({name: 'mfl/packs/create_pack_admin.tx', signers});

        // assert
        expect(error).toContain('Could not borrow pack admin ref');
      });

      test('should panic when trying to batch mint Packs with a non admin account', async () => {
        // prepare
        await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [bobAccountAddress]});
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [jackAccountAddress],
        });
        const argsMint = ['1', jackAccountAddress, '1'];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [bobAccountAddress],
        });

        // assert
        expect(error).toContain('PackAdminClaim capability not found');
      });
    });
  });

  describe('Collection', () => {
    describe('withdraw() / deposit()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [jackAccountAddress],
        });
        const argsMint = ['1', bobAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          code: WITHDRAW_PACK,
          args: [jackAccountAddress, '1'],
          signers: [bobAccountAddress],
        });

        // assert
        const expectedEvents = [
            ...testsUtils.createExpectedWithdrawEvent('MFLPack', '1', bobAccountAddress),
            ...testsUtils.createExpectedDepositedEvent('MFLPack', '1', jackAccountAddress),
        ]
        expect(result.events).toHaveLength(expectedEvents.length);
        expect(result.events).toEqual(expectedEvents);
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
        expect(jackPackIds).toHaveLength(1);
        expect(jackPackIds).toEqual(['1']);
      });

      test('should panic when trying to withdraw a NFT which is not in the collection', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const error = await testsUtils.shallRevert({
          code: WITHDRAW_PACK,
          args: [bobAccountAddress, '42'],
          signers: [bobAccountAddress],
        });

        // assert
        expect(error).toContain('missing NFT');
      });

      test('should not be able to withdraw a pack NFT from a collection that the user don\'t own', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [jackAccountAddress],
        });
        const argsMint = ['1', jackAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const err1 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, '1'],
        });
        const err2 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK_FROM_GIVEN_ADDRESS,
          signers: [bobAccountAddress],
          args: [jackAccountAddress, bobAccountAddress, '1'],
        });
        const err3 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V2,
          signers: [bobAccountAddress],
          args: [jackAccountAddress, bobAccountAddress, '1'],
        });
        await testsUtils.shallPass({
          code: WITHDRAW_PACK,
          signers: [jackAccountAddress],
          args: [bobAccountAddress, '1'],
        });
        const err4 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK,
          signers: [jackAccountAddress],
          args: [jackAccountAddress, '1'],
        });
        const err5 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK_FROM_GIVEN_ADDRESS,
          signers: [jackAccountAddress],
          args: [bobAccountAddress, jackAccountAddress, '1'],
        });
        const err6 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V2,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, jackAccountAddress, '1'],
        });
        const err7 = await testsUtils.shallRevert({
          code: BATCH_WITHDRAW_PACK_FROM_GIVEN_ADDRESS,
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, jackAccountAddress, ['1']],
        });
        const err8 = await testsUtils.shallRevert({
          code: BATCH_WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V2,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, jackAccountAddress, ['1']],
        });
        const err9 = await testsUtils.shallRevert({
          code: WITHDRAW_PACK_FROM_GIVEN_ADDRESS_V3,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, jackAccountAddress, '1'],
        });

        // assert
        expect(err1).toContain('missing NFT');
        expect(err2).toContain('Could not borrow the collection reference');
        expect(err3).toContain('function requires `Withdraw` authorization, but reference is unauthorized');
        expect(err4).toContain('missing NFT');
        expect(err5).toContain('Could not borrow the collection reference');
        expect(err6).toContain('function requires `Withdraw` authorization, but reference is unauthorized');
        expect(err7).toContain('Could not borrow the collection reference');
        expect(err8).toContain('function requires `Withdraw` authorization, but reference is unauthorized');
        expect(err9).toContain('function requires `Storage | BorrowValue` authorization, but reference is unauthorized');
      })
    });

    describe('batchWithdraw()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [jackAccountAddress],
        });
        const argsMint = ['1', bobAccountAddress, '2'];
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          code: BATCH_WITHDRAW_PACK,
          args: [jackAccountAddress, ['1', '2']],
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(16);
        expect(result.events).toEqual(
          expect.arrayContaining([
            ...testsUtils.createExpectedWithdrawEvent('MFLPack', '1', bobAccountAddress),
            ...testsUtils.createExpectedDepositedEvent('MFLPack', '1', null),
            ...testsUtils.createExpectedWithdrawEvent('MFLPack', '2', bobAccountAddress),
            ...testsUtils.createExpectedDepositedEvent('MFLPack', '2', null),
            ...testsUtils.createExpectedWithdrawEvent('MFLPack', '2', null),
            ...testsUtils.createExpectedDepositedEvent('MFLPack', '2', jackAccountAddress),
            ...testsUtils.createExpectedWithdrawEvent('MFLPack', '1', null),
            ...testsUtils.createExpectedDepositedEvent('MFLPack', '1', jackAccountAddress),
          ]),
        );
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
        expect(jackPackIds).toHaveLength(2);
        expect(jackPackIds).toEqual(expect.arrayContaining(['1', '2']));
      });
    });

    describe('getIDs()', () => {
      test('should get the IDs in the collection', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '10'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const bobPackIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });

        // assert
        // Bob should have 10 packs
        expect(bobPackIds).toHaveLength(10);
        expect(bobPackIds).toEqual(expect.arrayContaining(['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']));
      });
    });

    describe('borrowNFT()', () => {
      test('should borrow a NFT in the collection', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const pack = await testsUtils.executeValidScript({
          code: BORROW_NFT,
          args: [bobAccountAddress, '1'],
        });

        // assert
        expect(pack).toEqual({
          uuid: expect.toBeString(),
          id: '1',
          packTemplateID: '1',
        });
      });
    });

    describe('borrowViewResolver()', () => {
      test('should return a reference to a NFT as a MetadataViews.Resolver interface', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const pack = await testsUtils.executeValidScript({
          code: BORROW_VIEW_RESOLVER,
          args: [bobAccountAddress, '1'],
        });

        // assert
        expect(pack).toEqual({
          uuid: expect.toBeString(),
          id: '1',
          packTemplateID: '1',
        });
      });
    });

    describe('openPack()', () => {
      test('should burn a pack when opening it', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '2'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/players/create_and_link_player_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/clubs/create_and_link_club_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        await testsUtils.shallPass({
          name: 'mfl/packs/set_allow_to_open_packs.tx',
          args: ['1'],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/packs/open_pack.tx',
          args: ['2'],
          signers: [bobAccountAddress],
        });

        // assert
        const packIds = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        expect(packIds).toEqual(['1']);
        expect(result.events).toHaveLength(4);
        expect(result.events[0]).toEqual(testsUtils.createExpectedWithdrawEvent('MFLPack', '2', bobAccountAddress)[0]);
        expect(result.events[1]).toEqual(testsUtils.createExpectedWithdrawEvent('MFLPack', '2', bobAccountAddress)[1]);
        expect(result.events[2]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.Opened`,
            data: {
              id: '2',
              from: bobAccountAddress,
            },
          }),
        );
        expect(result.events[3]).toEqual(
          expect.objectContaining({
            type: `A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed`,
            data: {id: '2', uuid: expect.toBeString()},
          }),
        );
      });

      test('should throw an error when opening a pack not owned', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '2'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        const jackAccountAddress = await getAccountAddress('JackAccount');
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [jackAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        await testsUtils.shallPass({
          name: 'mfl/packs/set_allow_to_open_packs.tx',
          args: ['1'],
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const err1 = await testsUtils.shallRevert({
          code: OPEN_PACK_MALICIOUS,
          args: [bobAccountAddress, '2'],
          signers: [jackAccountAddress],
        });
        const err2 = await testsUtils.shallRevert({
          code: OPEN_PACK_MALICIOUS_V2,
          args: [bobAccountAddress, '2'],
          signers: [jackAccountAddress],
        });

        // assert
        expect(err1).toContain("Could not borrow the collection reference");
        expect(err2).toContain("function requires `PackAction` authorization, but reference is unauthorized");
      });

      test('should panic when opening a pack while the pack template is not openable', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '2'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/packs/open_pack.tx',
          args: ['2'],
          signers: [bobAccountAddress],
        });

        // assert
        expect(error).toContain('PackTemplate is not openable');
      });
    });

    describe('destroy()', () => {
      test('should destroy a collection', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '2'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          code: `
            import MFLPack from "../../../contracts/packs/MFLPack.cdc"
            
            transaction() {
            
                prepare(acct: auth(LoadValue) &Account) {
                    let collection <- acct.storage.load<@MFLPack.Collection>(from: MFLPack.CollectionStoragePath)!
                    destroy collection
                }
            }
          `,
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events).toEqual(
          expect.arrayContaining([
            {
              type: `A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed`,
              transactionId: expect.toBeString(),
              transactionIndex: expect.toBeNumber(),
              eventIndex: expect.toBeNumber(),
              data: {id: '1', uuid: expect.toBeString()},
            },
            {
              type: `A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed`,
              transactionId: expect.toBeString(),
              transactionIndex: expect.toBeNumber(),
              eventIndex: expect.toBeNumber(),
              data: {id: '2', uuid: expect.toBeString()},
            },
          ]),
        );
        const error = await testsUtils.executeFailingScript({
          name: 'mfl/packs/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        // Bob should no longer have a collection
        expect(error.message).toContain('Could not get receiver reference to the NFT Collection');
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
    describe('getViews()', () => {
      test('should get views types', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const viewsTypes = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_views_from_collection.script',
          args: [bobAccountAddress, '1'],
        });

        // assert
        expect(viewsTypes).toHaveLength(6);
        expect(viewsTypes.map((viewType) => viewType.typeID)).toEqual(
          expect.arrayContaining([
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Royalties`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionDisplay`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionData`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.ExternalURL`,
            `A.${testsUtils.sansPrefix(addressMap.MFLViews)}.MFLViews.PackDataViewV1`,
          ]),
        );
      });
    });

    describe('resolveView()', () => {
      test('should resolve Display view for a specific pack', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '1'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const packDisplayView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_display_view_from_collection.script',
          args: [bobAccountAddress, '1'],
        });

        // assert
        expect(packDisplayView).toEqual({
          name: argsPackTemplate.name,
          description: 'MFL Pack #1',
          thumbnail: argsPackTemplate.imageUrl,
          owner: bobAccountAddress,
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPack)}.MFLPack.NFT`,
        });
      });

      test('should resolve Royalties view for a specific pack', async () => {
        // prepare
        const argsMint = ['1', bobAccountAddress, '2'];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const packRoyaltiesView = await testsUtils.executeValidScript({
          code: GET_PACK_ROYALTIES_VIEW,
          args: [bobAccountAddress, '1'],
        });

        // assert
        expect(packRoyaltiesView).toEqual({
          cutInfos: [{
            receiver: {
              id: "0",
              address: '0x15e71a9f7fe7d53d',
              borrowType: {
                type: {
                  kind: 'Intersection',
                  typeID: '{A.ee82856bf20e2aa6.FungibleToken.Receiver}',
                  types: [{
                    type: '',
                    kind: 'ResourceInterface',
                    typeID: 'A.ee82856bf20e2aa6.FungibleToken.Receiver',
                    fields: [{type: {kind: 'UInt64'}, id: 'uuid'}],
                    initializers: [],
                  }],
                },
                kind: 'Reference',
                authorization: {
                  entitlements: null,
                  kind: 'Unauthorized',
                },
              },
            },
            cut: '0.05000000',
            description: 'Creator Royalty',
          }],
        });
      });

      test('should resolve Display view for all packs', async () => {
        // prepare
        const argsMint = ["1", bobAccountAddress, "2"];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const packsDisplayView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_packs_display_view_from_collection.script',
          args: [bobAccountAddress],
        });

        // assert
        expect(packsDisplayView).toHaveLength(2);
        expect(packsDisplayView).toEqual(
          expect.arrayContaining([
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
          ]),
        );
      });

      test('should resolve PackData view for a specific pack', async () => {
        // prepare
        const argsMint = ["1", bobAccountAddress, "1"];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const packDataView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_pack_data_view_from_collection.script',
          args: [bobAccountAddress, "1"],
        });

        // assert
        expect(packDataView).toEqual({
          id: "1",
          packTemplate: {
            id: "1",
            name: argsPackTemplate.name,
            description: argsPackTemplate.description,
            maxSupply: argsPackTemplate.maxSupply,
            currentSupply: "1",
            isOpenable: false,
            imageUrl: argsPackTemplate.imageUrl,
            type: argsPackTemplate.type,
            slots: [...Array(parseInt(argsPackTemplate.slotsNbr))].map((_, i) => {
              return {
                type: argsPackTemplate.slotsType[i],
                chances: argsPackTemplate.slotsChances[i],
                count: argsPackTemplate.slotsCount[i],
              };
            }),
          },
        });
      });

      test('should resolve PackData view for all packs', async () => {
        // prepare
        const argsMint = ["1", bobAccountAddress, "3"];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const packsDataView = await testsUtils.executeValidScript({
          name: 'mfl/packs/get_packs_data_view_from_collection.script',
          args: [bobAccountAddress],
        });

        // assert
        expect(packsDataView).toHaveLength(3);
        expect(packsDataView).toEqual(
          expect.arrayContaining([
            {
              id: "1",
              packTemplate: {
                id: "1",
                name: argsPackTemplate.name,
                description: argsPackTemplate.description,
                maxSupply: argsPackTemplate.maxSupply,
                currentSupply: "3",
                isOpenable: false,
                imageUrl: argsPackTemplate.imageUrl,
                type: argsPackTemplate.type,
                slots: [...Array(parseInt(argsPackTemplate.slotsNbr))].map((_, i) => {
                  return {
                    type: argsPackTemplate.slotsType[i],
                    chances: argsPackTemplate.slotsChances[i],
                    count: argsPackTemplate.slotsCount[i],
                  };
                }),
              },
            },
            {
              id: "2",
              packTemplate: {
                id: "1",
                name: argsPackTemplate.name,
                description: argsPackTemplate.description,
                maxSupply: argsPackTemplate.maxSupply,
                currentSupply: "3",
                isOpenable: false,
                imageUrl: argsPackTemplate.imageUrl,
                type: argsPackTemplate.type,
                slots: [...Array(parseInt(argsPackTemplate.slotsNbr))].map((_, i) => {
                  return {
                    type: argsPackTemplate.slotsType[i],
                    chances: argsPackTemplate.slotsChances[i],
                    count: argsPackTemplate.slotsCount[i],
                  };
                }),
              },
            },
            {
              id: "3",
              packTemplate: {
                id: "1",
                name: argsPackTemplate.name,
                description: argsPackTemplate.description,
                maxSupply: argsPackTemplate.maxSupply,
                currentSupply: "3",
                isOpenable: false,
                imageUrl: argsPackTemplate.imageUrl,
                type: argsPackTemplate.type,
                slots: [...Array(parseInt(argsPackTemplate.slotsNbr))].map((_, i) => {
                  return {
                    type: argsPackTemplate.slotsType[i],
                    chances: argsPackTemplate.slotsChances[i],
                    count: argsPackTemplate.slotsCount[i],
                  };
                }),
              },
            },
          ]),
        );
      });
    });

    describe('destroy()', () => {
      test('should destroy the NFT', async () => {
        // prepare
        const argsMint = ["1", bobAccountAddress, "1"];
        await testsUtils.shallPass({
          name: 'mfl/packs/create_and_link_pack_collection.tx',
          signers: [bobAccountAddress],
        });
        await testsUtils.shallPass({
          name: 'mfl/packs/batch_mint_pack.tx',
          args: argsMint,
          signers: [aliceAdminAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/packs/destroy_pack.tx',
          args: ["1"],
          signers: [bobAccountAddress],
        });

        // assert
        expect(result.events).toPartiallyContain({
          type: `A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed`,
          data: {id: "1", uuid: expect.toBeString()},
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

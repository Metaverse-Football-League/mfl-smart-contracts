import {emulator, getAccountAddress} from '@onflow/flow-js-testing';
import {MFLPlayerTestsUtils} from './_utils/MFLPlayerTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import {BORROW_VIEW_RESOLVER} from './_scripts/borrow_view_resolver.script';
import {ERROR_UPDATE_PLAYER_METADATA} from './_transactions/error_update_player_metadata.tx';
import {omit} from 'lodash';
import * as matchers from 'jest-extended';
import {GET_PLAYER_SERIAL_VIEW} from './_scripts/get_player_serial_view.script';
import {GET_PLAYER_ROYALTIES_VIEW} from './_scripts/get_player_royalties_view.script';
import {
  WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2,
} from './_transactions/withdraw_player_from_given_address_v2_malicious.tx';
import {WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS} from './_transactions/withdraw_player_from_given_address_malicious.tx';
import {
  BATCH_WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS,
} from './_transactions/batch_withdraw_player_from_given_address_malicious.tx';
import {
  BATCH_WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2,
} from './_transactions/batch_withdraw_player_from_given_address_malicious_v2.tx';
import {
  WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V3,
} from './_transactions/withdraw_player_from_given_address_v3_malicious.tx';
import {
  WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V4,
} from './_transactions/withdraw_player_from_given_address_v4_malicious.tx';
import {CREATE_PLAYER_LISTING} from './_transactions/create_player_listing.tx';
import {GET_PLAYER_METADATA_FOR_LISTING} from './_transactions/get_player_metadata_for_listing.script';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLPlayer', () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator();
    addressMap = await MFLPlayerTestsUtils.deployMFLPlayerContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('totalSupply', () => {
    test('should be able to get the totalSupply', async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: 'mfl/players/get_players_total_supply.script',
      });
      expect(totalSupply).toBe('0');
    });
  });

  describe('playersDatas', () => {
    test('should not be able to get the playersDatas', async () => {
      // prepare

      // execute
      const error = await testsUtils.executeFailingScript({
        code: `
          import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"
  
          access(all)
          fun main(): {UInt64: MFLPlayer.PlayerData} {
              return MFLPlayer.playersDatas
          }
        `,
        addressMap,
      });

      // assert
      expect(error.message).toContain('cannot access `playersDatas`: field requires `self` authorization');
    });
  });

  describe('Collection', () => {
    describe('withdraw() / deposit()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({
          name: 'mfl/players/create_and_link_player_collection.tx',
          signers: [bobAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/players/withdraw_player.tx',
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, '1'],
        });

        // assert
        const expectedEvents = [
            ...testsUtils.createExpectedWithdrawEvent('MFLPlayer', '1', aliceAdminAccountAddress),
            ...testsUtils.createExpectedDepositedEvent('MFLPlayer', '1', bobAccountAddress),
        ]
        expect(result.events).toHaveLength(expectedEvents.length);
        expect(result.events[0]).toEqual(expectedEvents[0]);
        expect(result.events[1]).toEqual(expectedEvents[1]);
        expect(result.events[2]).toEqual(expectedEvents[2]);
        expect(result.events[3]).toEqual(expectedEvents[3]);
        const alicePlayersIds = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [aliceAdminAccountAddress],
        });
        expect(alicePlayersIds).toEqual([]);
        const bobPlayersIds = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        expect(bobPlayersIds).toEqual(['1']);
      });

      test('should not be able to withdraw a player NFT from a collection that the user don\'t own', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({
          name: 'mfl/players/create_and_link_player_collection.tx',
          signers: [bobAccountAddress],
        });

        // execute
        const err1 = await testsUtils.shallRevert({
          name: 'mfl/players/withdraw_player.tx',
          signers: [bobAccountAddress],
          args: [bobAccountAddress, '1'],
        });
        const err2 = await testsUtils.shallRevert({
          code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS,
          signers: [bobAccountAddress],
          args: [aliceAdminAccountAddress, bobAccountAddress, '1'],
        });
        const err3 = await testsUtils.shallRevert({
          code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2,
          signers: [bobAccountAddress],
          args: [aliceAdminAccountAddress, bobAccountAddress, '1'],
        });
        await testsUtils.shallPass({
          name: 'mfl/players/withdraw_player.tx',
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, '1'],
        });
        const err4 = await testsUtils.shallRevert({
          name: 'mfl/players/withdraw_player.tx',
          signers: [aliceAdminAccountAddress],
          args: [aliceAdminAccountAddress, '1'],
        });
        const err5 = await testsUtils.shallRevert({
          code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS,
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, aliceAdminAccountAddress, '1'],
        });
        const err6 = await testsUtils.shallRevert({
          code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, aliceAdminAccountAddress, '1'],
        });
        const err7 = await testsUtils.shallRevert({
          code: BATCH_WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS,
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, aliceAdminAccountAddress, ['1']],
        });
        const err8 = await testsUtils.shallRevert({
          code: BATCH_WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, aliceAdminAccountAddress, ['1']],
        });
        const err9 = await testsUtils.shallRevert({
          code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V3,
          signers: [bobAccountAddress],
          args: [bobAccountAddress, aliceAdminAccountAddress, '1'],
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
      });
    });

    describe('batchWithdraw()', () => {
      test('should batch withdraw NFTs from a collection and batch deposit them in another collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('1');
        await MFLPlayerTestsUtils.createPlayerNFT('31');
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({
          name: 'mfl/players/create_and_link_player_collection.tx',
          signers: [bobAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/players/batch_withdraw_players.tx',
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, ['1', '31']],
        });

        // assert
        expect(result.events).toHaveLength(16);
        expect(result.events).toEqual(
          expect.arrayContaining([
            ...testsUtils.createExpectedWithdrawEvent('MFLPlayer', '1', aliceAdminAccountAddress),
            ...testsUtils.createExpectedWithdrawEvent('MFLPlayer', '31', aliceAdminAccountAddress),
            ...testsUtils.createExpectedDepositedEvent('MFLPlayer', '1', null),
            ...testsUtils.createExpectedDepositedEvent('MFLPlayer', '31', null),
            ...testsUtils.createExpectedWithdrawEvent('MFLPlayer', '1', null),
            ...testsUtils.createExpectedDepositedEvent('MFLPlayer', '1', bobAccountAddress),
            ...testsUtils.createExpectedWithdrawEvent('MFLPlayer', '31', null),
            ...testsUtils.createExpectedDepositedEvent('MFLPlayer', '31', bobAccountAddress),
          ]),
        );

        const alicePlayersIds = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [aliceAdminAccountAddress],
        });
        expect(alicePlayersIds).toEqual([]);
        const bobPlayersIds = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        expect(bobPlayersIds).toHaveLength(2);
        expect(bobPlayersIds).toEqual(expect.arrayContaining(['1', '31']));
      });
    });

    describe('getIDs()', () => {
      test('should get the IDs in the collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');
        await MFLPlayerTestsUtils.createPlayerNFT('1');
        await MFLPlayerTestsUtils.createPlayerNFT('89');

        // execute
        const ids = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [aliceAdminAccountAddress],
        });

        // assert
        expect(ids).toHaveLength(3);
        expect(ids).toEqual(expect.arrayContaining(['100022', '1', '89']));
      });
    });

    describe('borrowNFT()', () => {
      test('should borrow a NFT in the collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        const playerID = '5';
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const playerFromCollection = await testsUtils.executeValidScript({
          code: `
            import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
            import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"

            access(all)
            fun main(address: Address, playerID: UInt64): &{NonFungibleToken.NFT}? {
                let playerCollectionRef = getAccount(address).capabilities.borrow<&MFLPlayer.Collection>(
                    MFLPlayer.CollectionPublicPath
                ) ?? panic("Could not borrow the collection reference")
                let nftRef = playerCollectionRef.borrowNFT(playerID)
                return nftRef
            }
          `,
          args: [aliceAdminAccountAddress, playerID],
        });

        // assert
        expect(playerFromCollection).toEqual({
          id: playerID,
          season: MFLPlayerTestsUtils.PLAYER_DATA.season,
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
          uuid: expect.toBeString(),
        });
      });
    });

    describe('destroy', () => {
      test('should destroy a collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('1');
        await MFLPlayerTestsUtils.createPlayerNFT('23');

        // execute
        const result = await testsUtils.shallPass({
          code: `
            import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
            
            transaction() {
            
                prepare(acct: auth(LoadValue) &Account) {
                    let collection <- acct.storage.load<@MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath)!
                    destroy collection
                }
            }
          `,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events).toPartiallyContain({
          type: 'A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed',
          data: {id: '1', uuid: expect.toBeString()},
        });
        expect(result.events).toPartiallyContain({
          type: 'A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed',
          data: {id: '23', uuid: expect.toBeString()},
        });
      });
    });
  });

  describe('createEmptyCollection()', () => {
    test('should create an empty collection', async () => {
      // prepare
      const bobAccountAddress = await getAccountAddress('BobAccount');

      // execute
      await testsUtils.shallPass({
        name: 'mfl/players/create_and_link_player_collection.tx',
        signers: [bobAccountAddress],
      });

      // assert
      await testsUtils.executeValidScript({
        name: 'mfl/players/get_ids_in_collection.script',
        args: [bobAccountAddress],
      });
    });
  });

  describe('NFT', () => {
    describe('getViews()', () => {
      test('should get views types', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');

        // execute
        const viewsTypes = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_views_from_collection.script',
          args: [aliceAdminAccountAddress, '100022'],
        });

        // assert
        expect(viewsTypes.map((viewType) => viewType.typeID)).toEqual(
          expect.arrayContaining([
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Royalties`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionDisplay`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionData`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.ExternalURL`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Traits`,
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Serial`,
            `A.${testsUtils.sansPrefix(addressMap.MFLViews)}.MFLViews.PlayerDataViewV1`,
          ]),
        );
      });
    });

    describe('resolveView()', () => {
      test('should resolve Display view for a specific player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');

        // execute
        const playerDisplayView = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_display_view_from_collection.script',
          args: [aliceAdminAccountAddress, '100022'],
        });

        // assert
        expect(playerDisplayView).toEqual({
          name: 'some name',
          description: 'Before purchasing this MFL Player, make sure to check the player\'s in-game profile for the latest information: https://app.playmfl.com/players/100022',
          thumbnail: 'https://d13e14gtps4iwl.cloudfront.net/players/100022/card.png?co=87',
          owner: aliceAdminAccountAddress,
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`,
        });
      });

      test('should resolve Royalties view for a specific player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');

        // execute
        const playerRoyaltiesView = await testsUtils.executeValidScript({
          code: GET_PLAYER_ROYALTIES_VIEW,
          args: [aliceAdminAccountAddress, '100022'],
        });

        // assert
        expect(playerRoyaltiesView).toEqual({
          'cutInfos': [{
            'receiver': {
              'borrowType': {
                'type': {
                  'kind': 'Intersection',
                  'typeID': '{A.ee82856bf20e2aa6.FungibleToken.Receiver}',
                  'types': [{
                    'type': '',
                    'kind': 'ResourceInterface',
                    'typeID': 'A.ee82856bf20e2aa6.FungibleToken.Receiver',
                    'fields': [{'type': {'kind': 'UInt64'}, 'id': 'uuid'}],
                    'initializers': [],
                  }],
                }, 'kind': 'Reference', 'authorization': {'kind': 'Unauthorized', 'entitlements': null},
              }, 'address': '0x15e71a9f7fe7d53d', 'id': '0',
            }, 'cut': '0.05000000', 'description': 'Creator Royalty',
          }],
        });
      });

      test('should resolve Traits view for a specific player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');

        // execute
        const playerTraitsView = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_traits_view_from_collection.script',
          args: [aliceAdminAccountAddress, '100022'],
        });

        // assert
        expect(playerTraitsView).toEqual({
          traits: [
            {
              name: 'name',
              value: 'some name',
              displayType: 'String',
              rarity: null,
            },
            {
              name: 'nationalities',
              value: 'FR, DE',
              displayType: 'String',
              rarity: null,
            },
            {
              name: 'positions',
              value: 'ST, CAM',
              displayType: 'String',
              rarity: null,
            },
            {
              name: 'preferredFoot',
              value: 'left',
              displayType: 'String',
              rarity: null,
            },
            {
              name: 'ageAtMint',
              value: '17',
              displayType: 'Number',
              rarity: null,
            },
            {name: 'height', value: '18', displayType: 'Number', rarity: null},
            {name: 'overall', value: '87', displayType: 'Number', rarity: null},
            {name: 'pace', value: '56', displayType: 'Number', rarity: null},
            {
              name: 'shooting',
              value: '66',
              displayType: 'Number',
              rarity: null,
            },
            {name: 'passing', value: '62', displayType: 'Number', rarity: null},
            {
              name: 'dribbling',
              value: '61',
              displayType: 'Number',
              rarity: null,
            },
            {name: 'defense', value: '60', displayType: 'Number', rarity: null},
            {
              name: 'physical',
              value: '59',
              displayType: 'Number',
              rarity: null,
            },
            {
              name: 'goalkeeping',
              value: '1',
              displayType: 'Number',
              rarity: null,
            },
          ],
        });
      });

      test('should resolve Serial view for a specific player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');

        // execute
        const playerSerialView = await testsUtils.executeValidScript({
          code: GET_PLAYER_SERIAL_VIEW,
          args: [aliceAdminAccountAddress, '100022'],
        });

        // assert
        expect(playerSerialView).toEqual({number: '100022'});
      });

      test('should resolve Display view for all players', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');
        await MFLPlayerTestsUtils.createPlayerNFT('100023');

        // execute
        const playersDisplayView = await testsUtils.executeValidScript({
          name: 'mfl/players/get_players_display_view_from_collection.script',
          args: [aliceAdminAccountAddress, ['100022', '100023']],
        });

        // assert
        expect(playersDisplayView).toEqual(
          expect.arrayContaining([
            {
              name: 'some name',
              description: 'Before purchasing this MFL Player, make sure to check the player\'s in-game profile for the latest information: https://app.playmfl.com/players/100022',
              thumbnail: 'https://d13e14gtps4iwl.cloudfront.net/players/100022/card.png?co=87',
              owner: aliceAdminAccountAddress,
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`,
            },
            {
              name: 'some name',
              description: 'Before purchasing this MFL Player, make sure to check the player\'s in-game profile for the latest information: https://app.playmfl.com/players/100023',
              thumbnail: 'https://d13e14gtps4iwl.cloudfront.net/players/100023/card.png?co=87',
              owner: aliceAdminAccountAddress,
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`,
            },
          ]),
        );
      });

      test('should resolve PlayerData view for a specific player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        const playerID = '100022';
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const playerDataView = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_data_view_from_collection.script',
          args: [aliceAdminAccountAddress, playerID],
        });

        // assert
        expect(playerDataView).toEqual({
          id: playerID,
          season: '1',
          thumbnail: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
          metadata: omit(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY, 'longevity'),
        });
      });

      test('should resolve PlayerData view for all players', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        const playerID1 = '100022';
        const playerID2 = '100023';
        await MFLPlayerTestsUtils.createPlayerNFT(playerID1);
        await MFLPlayerTestsUtils.createPlayerNFT(playerID2);

        // execute
        const playersDataView = await testsUtils.executeValidScript({
          name: 'mfl/players/get_players_data_view_from_collection.script',
          args: [aliceAdminAccountAddress, ['100022', '100023']],
        });

        // assert
        expect(playersDataView).toEqual(
          expect.arrayContaining([
            {
              id: playerID1,
              season: '1',
              thumbnail: {
                cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
                path: null,
              },
              metadata: omit(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY, 'longevity'),
            },
            {
              id: playerID2,
              season: '1',
              thumbnail: {
                cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
                path: null,
              },
              metadata: omit(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY, 'longevity'),
            },
          ]),
        );
      });
    });

    describe('destroy()', () => {
      test('should destroy the NFT', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        await MFLPlayerTestsUtils.createPlayerNFT('100022');

        // execute
        const signers = [aliceAdminAccountAddress];
        const args = ['100022'];
        const result = await testsUtils.shallPass({name: 'mfl/players/destroy_player.tx', args, signers});

        // assert
        expect(result.events).toPartiallyContain({
          type: `A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed`,
          data: {id: '100022', uuid: expect.toBeString()},
        });
        const error = await testsUtils.executeFailingScript({
          name: 'mfl/players/get_player_data_view_from_collection.script',
          args: [aliceAdminAccountAddress, '100022'],
        });
        expect(error.message).toContain('unexpectedly found nil while forcing an Optional value');
      });
    });
  });

  describe('getPlayerData()', () => {
    test('should get player data', async () => {
      // prepare
      await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
      const playerID = '4';
      await MFLPlayerTestsUtils.createPlayerNFT(playerID);

      // execute
      const playerData = await testsUtils.executeValidScript({
        name: 'mfl/players/get_player_data.script',
        args: [playerID],
      });

      // assert
      expect(playerData).toEqual({
        id: playerID,
        metadata: MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY,
        season: '1',
        image: {
          cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
          path: null,
        },
      });
    });

    test('should return nil when getting player data for an unknown player', async () => {
      // prepare

      // execute
      const playerData = await testsUtils.executeValidScript({
        name: 'mfl/players/get_player_data.script',
        args: ['4'],
      });

      // assert
      expect(playerData).toBeNull();
    });

    test('should throw an error when updating player metadata', async () => {
      // prepare
      await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
      await MFLPlayerTestsUtils.createPlayerNFT(1);

      // execute
      const error = await testsUtils.shallRevert({
        code: ERROR_UPDATE_PLAYER_METADATA,
        args: ['1'],
      });

      // assert
      expect(error).toContain('cannot access `metadata`: field requires `contract` authorization');
    });
  });

  describe('PlayerAdmin', () => {
    describe('mintPlayer()', () => {
      test('should mint a player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );

        // execute
        const signers = [aliceAdminAccountAddress];
        const playerID = '1201';
        const args = [
          playerID,
          1,
          'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
          ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY),
          aliceAdminAccountAddress,
        ];
        const result = await testsUtils.shallPass({name: 'mfl/players/mint_player.tx', args, signers});

        // assert
        expect(result.events).toHaveLength(3);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Minted`,
            data: {id: playerID},
          }),
        );
        expect(result.events[1]).toEqual(
          testsUtils.createExpectedDepositedEvent('MFLPlayer', playerID, aliceAdminAccountAddress)[0],
        );
        expect(result.events[2]).toEqual(
          testsUtils.createExpectedDepositedEvent('MFLPlayer', playerID, aliceAdminAccountAddress)[1],
        );
        const playerData = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_data.script',
          args: [playerID],
        });
        expect(playerData).toEqual({
          id: playerID,
          metadata: MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY,
          season: '1',
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
        });
        const totalSupply = await testsUtils.executeValidScript({
          name: 'mfl/players/get_players_total_supply.script',
        });
        expect(totalSupply).toBe('1');
        const playerFromCollection = await testsUtils.executeValidScript({
          code: BORROW_VIEW_RESOLVER,
          args: [aliceAdminAccountAddress, playerID],
        });
        expect(playerFromCollection).toEqual({
          id: playerID,
          season: '1',
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
          uuid: expect.toBeString(),
        });
      });

      test('should panic when minting a player id already minted', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );

        // execute
        const signers = [aliceAdminAccountAddress];
        const playerID = '1201';
        const args = [
          playerID,
          1,
          'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
          ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY),
          aliceAdminAccountAddress,
        ];
        await testsUtils.shallPass({name: 'mfl/players/mint_player.tx', args, signers});
        const error = await testsUtils.shallRevert({name: 'mfl/players/mint_player.tx', args, signers});

        // assert
        expect(error).toContain('Player already exists');
      });
    });

    describe('updatePlayerMetadata()', () => {
      test('should update player metadata', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        const signers = [aliceAdminAccountAddress];
        const playerID = '1200';
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const updatedMetadata = {...MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY};
        updatedMetadata.positions = ['ST', 'RW', 'LW'];
        updatedMetadata.overall = '99';
        const result = await testsUtils.shallPass({
          name: 'mfl/players/update_player_metadata.tx',
          args: [playerID, ...Object.values(updatedMetadata), aliceAdminAccountAddress],
          signers,
        });

        // assert
        const playerData = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_data.script',
          args: [playerID],
        });
        expect(playerData).toEqual({
          id: playerID,
          metadata: updatedMetadata,
          season: '1',
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
        });
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Updated`,
            data: {id: playerID},
          }),
        );
        expect(result.events[1]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.NonFungibleToken)}.NonFungibleToken.Updated`,
            data: {id: playerID, owner: aliceAdminAccountAddress, type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`, uuid: expect.any(String)},
          }),
        );
      });

      test('should panic when updating a player metadata for an unknown player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        const signers = [aliceAdminAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/players/update_player_metadata.tx',
          args: ['1201', ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY), aliceAdminAccountAddress],
          signers,
        });

        // assert
        expect(error).toContain('Data not found');
      });
    });

    describe('createPlayerAdmin()', () => {
      test('should create a player admin', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          'AliceAdminAccount',
          'AliceAdminAccount',
        );
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');

        // execute
        const signers = [aliceAdminAccountAddress, bobAccountAddress];
        await testsUtils.shallPass({
          name: 'mfl/players/create_player_admin.tx',
          signers,
        });

        // assert
        // bob must now be able to create another player admin
        await testsUtils.shallPass({
          name: 'mfl/players/create_player_admin.tx',
          signers: [bobAccountAddress, jackAccountAddress],
        });
      });

      test('should panic when trying to create a player admin with a non admin account', async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress('BobAccount');
        const jackAccountAddress = await getAccountAddress('JackAccount');

        // execute
        const signers = [bobAccountAddress, jackAccountAddress];
        const error = await testsUtils.shallRevert({
          name: 'mfl/players/create_player_admin.tx',
          signers,
        });

        // assert
        expect(error).toContain('Could not borrow player admin ref');
      });
    });
  });

  describe('Storefornt', () => {
    test('should list a player for sale', async () => {
      // prepare
      const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
        'AliceAdminAccount',
        'AliceAdminAccount',
      );
      await MFLPlayerTestsUtils.createPlayerNFT(1);
      const bobAccountAddress = await getAccountAddress('BobAccount');
      await testsUtils.shallPass({
        name: 'mfl/players/create_and_link_player_collection.tx',
        signers: [bobAccountAddress],
      });
      await testsUtils.shallPass({
        name: 'mfl/players/withdraw_player.tx',
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, '1'],
      });
      await testsUtils.shallPass({
        name: 'storefront/initialize_duc_receiver.tx',
        signers: [bobAccountAddress],
      });
      await testsUtils.shallPass({
        name: 'storefront/initialize_duc_receiver.tx',
        signers: [aliceAdminAccountAddress],
      });

      // execute
      const result = await testsUtils.shallPass({
        code: CREATE_PLAYER_LISTING,
        args: ['1', '100', '0.2'],
        signers: [aliceAdminAccountAddress, bobAccountAddress],
      });
      const listingEvent = result.events.find((event) => event.type === 'A.f8d6e0586b0a20c7.NFTStorefront.ListingAvailable');
      const listingResourceId = listingEvent.data.listingResourceID;
      const output = await testsUtils.executeValidScript({
        code: GET_PLAYER_METADATA_FOR_LISTING,
        args: [bobAccountAddress, listingResourceId],
      });

      // assert
      expect(output.amount).toEqual('100.00000000');
    });

    test('should list a player for sale v2', async () => {
      // prepare
      const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
        'AliceAdminAccount',
        'AliceAdminAccount',
      );
      await MFLPlayerTestsUtils.createPlayerNFT(1);
      await MFLPlayerTestsUtils.createPlayerNFT(2);
      const bobAccountAddress = await getAccountAddress('BobAccount');
      await testsUtils.shallPass({
        name: 'mfl/players/create_and_link_player_collection.tx',
        signers: [bobAccountAddress],
      });
      await testsUtils.shallPass({
        name: 'mfl/players/withdraw_player.tx',
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, '1'],
      });
      await testsUtils.shallPass({
        name: 'mfl/players/withdraw_player.tx',
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, '2'],
      });
      await testsUtils.shallPass({
        name: 'storefront/initialize_duc_receiver.tx',
        signers: [bobAccountAddress],
      });
      await testsUtils.shallPass({
        name: 'storefront/initialize_duc_receiver.tx',
        signers: [aliceAdminAccountAddress],
      });

      // execute
      const result = await testsUtils.shallPass({
        name: 'mfl/players/create_player_listing_v2.tx',
        args: ['1', '100', '0.2'],
        signers: [aliceAdminAccountAddress, bobAccountAddress],
      });
      const err1 = await testsUtils.shallRevert({
        code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS,
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, aliceAdminAccountAddress, '2'],
      });
      const err2 = await testsUtils.shallRevert({
        code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V2,
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, aliceAdminAccountAddress, '2'],
      });
      const err3 = await testsUtils.shallRevert({
        code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V3,
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, aliceAdminAccountAddress, '2'],
      });
      const err4 = await testsUtils.shallRevert({
        code: WITHDRAW_PLAYER_FROM_GIVEN_ADDRESS_V4,
        signers: [aliceAdminAccountAddress],
        args: [bobAccountAddress, aliceAdminAccountAddress, '2'],
      });

      const listingEvent = result.events.find((event) => event.type === 'A.f8d6e0586b0a20c7.NFTStorefront.ListingAvailable');
      const listingResourceId = listingEvent.data.listingResourceID;
      const output = await testsUtils.executeValidScript({
        code: GET_PLAYER_METADATA_FOR_LISTING,
        args: [bobAccountAddress, listingResourceId],
      });

      // assert
      expect(output.amount).toEqual('100.00000000');
      expect(err1).toContain("Could not borrow the collection reference")
      expect(err2).toContain("requires `Withdraw` authorization")
      expect(err3).toContain("requires `Storage | BorrowValue` authorization")
      expect(err4).toContain("requires `Storage | CopyValue` authorization")
    });
  });
});

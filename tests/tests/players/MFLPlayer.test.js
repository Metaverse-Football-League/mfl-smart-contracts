import {emulator, getAccountAddress} from 'flow-js-testing';
import {MFLPlayerTestsUtils} from './_utils/MFLPlayerTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLPlayer', () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8080);
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
      expect(totalSupply).toBe(0);
    });
  });

  describe('playersDatas', () => {
    test('should not be able to get the playersDatas', async () => {
      // prepare

      // execute
      const error = await testsUtils.executeFailingScript({
        code: `
          import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"
  
          pub fun main(): {UInt64: MFLPlayer.PlayerData} {
              return MFLPlayer.playersDatas
          }
        `,
        addressMap,
      });

      // assert
      expect(error.message).toContain('field has private access');
    });
  });

  describe('Collection', () => {
    describe('withdraw() / deposit()', () => {
      test('should withdraw a NFT from a collection and deposit it in another collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
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
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
          data: {id: 1, from: aliceAdminAccountAddress},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
          data: {id: 1, to: bobAccountAddress},
        }));
        const alicePlayersIds = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [aliceAdminAccountAddress],
        });
        expect(alicePlayersIds).toEqual([]);
        const bobPlayersIds = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [bobAccountAddress],
        });
        expect(bobPlayersIds).toEqual([1]);
      });
    });

    describe('batchWithdraw() / batchDeposit()', () => {
      test('should batch withdraw NFTs from a collection and batch deposit them in another collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        await MFLPlayerTestsUtils.createPlayerNFT(31);
        const bobAccountAddress = await getAccountAddress('BobAccount');
        await testsUtils.shallPass({
          name: 'mfl/players/create_and_link_player_collection.tx',
          signers: [bobAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: 'mfl/players/batch_withdraw_players.tx',
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, [1, 31]],
        });

        // assert
        expect(result.events).toHaveLength(8);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
          data: {id: 1, from: aliceAdminAccountAddress},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
          data: {id: 1, to: null},
        }));
        expect(result.events[2]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
          data: {id: 31, from: aliceAdminAccountAddress},
        }));
        expect(result.events[3]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
          data: {id: 31, to: null},
        }));
        expect(result.events[4]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
          data: {id: 1, from: null},
        }));
        expect(result.events[5]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
          data: {id: 1, to: bobAccountAddress},
        }));
        expect(result.events[6]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
          data: {id: 31, from: null},
        }));
        expect(result.events[7]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
          data: {id: 31, to: bobAccountAddress},
        }));
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
        expect(bobPlayersIds).toEqual(expect.arrayContaining([1, 31]));
      });
    });

    describe('getIDs()', () => {
      test('should get the IDs in the collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(100022);
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        await MFLPlayerTestsUtils.createPlayerNFT(89);

        // execute
        const ids = await testsUtils.executeValidScript({
          name: 'mfl/players/get_ids_in_collection.script',
          args: [aliceAdminAccountAddress],
        });

        // assert
        expect(ids).toHaveLength(3);
        expect(ids).toEqual(expect.arrayContaining([100022, 1, 89]));
      });
    });

    describe('borrowNFT()', () => {
      test('should borrow a NFT in the collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(5);

        // execute
        const playerFromCollection = await testsUtils.executeValidScript({
          code: `
            import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
            import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"

            pub fun main(address: Address, playerID: UInt64): &NonFungibleToken.NFT {
                let playerCollectionRef = getAccount(address).getCapability<&{MFLPlayer.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
                    ?? panic("Could not borrow the collection reference")
                let nftRef = playerCollectionRef.borrowNFT(id: playerID)
                return nftRef
            }
          `,
          args: [aliceAdminAccountAddress, 5],
        });

        // assert
        expect(playerFromCollection).toEqual({
          id: 5,
          season: MFLPlayerTestsUtils.PLAYER_DATA.season,
          folderCID: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
          uuid: expect.toBeNumber(),
        });
      });
    });

    describe('borrowPlayer()', () => {
      test('should borrow a player in the collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(5);

        // execute
        const playerFromCollection = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_from_collection.script',
          args: [aliceAdminAccountAddress, 5],
        });

        // assert
        expect(playerFromCollection).toEqual({
          id: 5,
          season: MFLPlayerTestsUtils.PLAYER_DATA.season,
          folderCID: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
          uuid: expect.toBeNumber(),
        });
      });
    });

    describe('destroy', () => {
      test('should destroy a collection', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        await MFLPlayerTestsUtils.createPlayerNFT(23);

        // execute
        const result = await testsUtils.shallPass({
          code: `
            import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"
            
            transaction() {
            
                prepare(acct: AuthAccount) {
                    let collection <- acct.load<@MFLPlayer.Collection>(from: MFLPlayer.CollectionStoragePath)!
                    destroy collection
                }
            }
          `,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Destroyed`,
          data: {id: 1},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Destroyed`,
          data: {id: 23},
        }));
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
        name: 'mfl/players/get_player_from_collection.script',
        args: [bobAccountAddress, 1],
      });
    });
  });

  describe('NFT', () => {
    describe('getData()', () => {
      test('should be able to get data', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(2);

        // execute
        const playerDataFromCollection = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_data_from_collection.script',
          args: [aliceAdminAccountAddress, 2],
        });

        // assert
        expect(playerDataFromCollection).toEqual({
          id: 2,
          folderCID: 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
          season: 1,
          metadata: MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY,
        });
      });
    });

    describe('destroy()', () => {
      test('should destroy the NFT', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        await MFLPlayerTestsUtils.createPlayerNFT(100022);

        // execute
        const signers = [aliceAdminAccountAddress];
        const args = [100022];
        const result = await testsUtils.shallPass({name: 'mfl/players/destroy_player.tx', args, signers});

        // assert
        expect(result.events).toPartiallyContain({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Destroyed`,
          data: {id: 100022},
        });
        const playerDataFromCollection = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_data_from_collection.script',
          args: [aliceAdminAccountAddress, 100022],
        });
        expect(playerDataFromCollection).toBeNull();
      });
    });
  });

  describe('fetch()', () => {
    test('should fetch a player reference from an account', async () => {
      // prepare
      const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
      await MFLPlayerTestsUtils.createPlayerNFT(54);

      // execute
      const player = await testsUtils.executeValidScript({
        name: 'mfl/players/fetch_player.script',
        args: [aliceAdminAccountAddress, 54],
      });

      // assert
      expect(player).toEqual({
        uuid: expect.toBeNumber(),
        id: 54,
        season: 1,
        folderCID: 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
      });
    });

    test('should return nil when fetching a player reference not in the account\'s collection', async () => {
      // prepare
      const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');

      // execute
      const player = await testsUtils.executeValidScript({
        name: 'mfl/players/fetch_player.script',
        args: [aliceAdminAccountAddress, 54],
      });

      // assert
      expect(player).toBeNull();
    });

    test('should panic when fetching a player reference from an account without the correct capability', async () => {
      // prepare
      const bobAccountAddress = await getAccountAddress('BobAccount');

      // execute
      const error = await testsUtils.executeFailingScript({
        name: 'mfl/players/fetch_player.script',
        args: [bobAccountAddress, 54],
      });

      // assert
      expect(error.message).toContain('Couldn\'t get collection');
    });
  });

  describe('getPlayerData()', () => {
    test('should get player data', async () => {
      // prepare
      await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
      await MFLPlayerTestsUtils.createPlayerNFT(4);

      // execute
      const playerData = await testsUtils.executeValidScript({
        name: 'mfl/players/get_player_data.script',
        args: [4],
      });

      // assert
      expect(playerData).toEqual({
        ...MFLPlayerTestsUtils.PLAYER_DATA,
        id: 4,
      });
    });

    test('should return nil when getting player data for an unknown player', async () => {
      // prepare

      // execute
      const playerData = await testsUtils.executeValidScript({
        name: 'mfl/players/get_player_data.script',
        args: [4],
      });

      // assert
      expect(playerData).toBeNull();
    });
  });

  describe('PlayerAdmin', () => {
    describe('mintPlayer()', () => {
      test('should mint a player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');

        // execute
        const signers = [aliceAdminAccountAddress];
        const playerID = 1201;
        const args = [playerID, 1, 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm', ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY)];
        const result = await testsUtils.shallPass({name: 'mfl/players/mint_player.tx', args, signers});

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Minted`,
          data: {id: playerID},
        }));
        expect(result.events[1]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
          data: {id: playerID, to: aliceAdminAccountAddress},
        }));
        const playerData = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_data.script',
          args: [playerID],
        });
        expect(playerData).toEqual({
          id: playerID,
          metadata: MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY,
          season: 1,
          folderCID: 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
        });
        const totalSupply = await testsUtils.executeValidScript({
          name: 'mfl/players/get_players_total_supply.script',
        });
        expect(totalSupply).toBe(1);
        const playerFromCollection = await testsUtils.executeValidScript({
          name: 'mfl/players/get_player_from_collection.script',
          args: [aliceAdminAccountAddress, playerID],
        });
        expect(playerFromCollection).toEqual({
          id: playerID,
          season: 1,
          folderCID: 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
          uuid: expect.toBeNumber(),
        });
      });

      test('should panic when minting a player id already minted', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');

        // execute
        const signers = [aliceAdminAccountAddress];
        const playerID = 1201;
        const args = [playerID, 1, 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm', ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY)];
        await testsUtils.shallPass({name: 'mfl/players/mint_player.tx', args, signers});
        const error = await testsUtils.shallRevert({name: 'mfl/players/mint_player.tx', args, signers});

        // assert
        expect(error).toContain('Player already exists');
      });
    });

    describe('updatePlayerMetadata()', () => {
      test('should update player metadata', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];
        const playerID = 1200;
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const updatedMetadata = {...MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY};
        updatedMetadata.positions = ['ST', 'RW', 'LW'];
        updatedMetadata.overall = 99;
        const result = await testsUtils.shallPass({
          name: 'mfl/players/update_player_metadata.tx',
          args: [playerID, ...Object.values(updatedMetadata)],
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
          season: 1,
          folderCID: 'QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm',
        });
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(expect.objectContaining({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Updated`,
          data: {id: playerID},
        }));
      });

      test('should panic when updating a player metadata for an unknown player', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
        const signers = [aliceAdminAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({
          name: 'mfl/players/update_player_metadata.tx',
          args: [1201, ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY)],
          signers,
        });

        // assert
        expect(error).toContain('Data not found');
      });
    });

    describe('createPlayerAdmin()', () => {
      test('should create a player admin', async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin('AliceAdminAccount', 'AliceAdminAccount');
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
});

import { emulator, getAccountAddress } from "flow-js-testing";
import { MFLPlayerTestsUtils } from "./_utils/MFLPlayerTests.utils";
import { testsUtils } from "../_utils/tests.utils";
import { BORROW_VIEW_RESOLVER } from "./_scripts/borrow_view_resolver.script";
import { ERROR_UPDATE_PLAYER_METADATA } from "./_transactions/error_update_player_metadata.tx";
import { omit } from "lodash";
import * as matchers from "jest-extended";

expect.extend(matchers);
jest.setTimeout(40000);

describe("MFLPlayer", () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8080);
    addressMap = await MFLPlayerTestsUtils.deployMFLPlayerContract("AliceAdminAccount");
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe("totalSupply", () => {
    test("should be able to get the totalSupply", async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: "mfl/players/get_players_total_supply.script",
      });
      expect(totalSupply).toBe(0);
    });
  });

  describe("playersDatas", () => {
    test("should not be able to get the playersDatas", async () => {
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
      expect(error.message).toContain("field has private access");
    });
  });

  describe("Collection", () => {
    describe("withdraw() / deposit()", () => {
      test("should withdraw a NFT from a collection and deposit it in another collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        const bobAccountAddress = await getAccountAddress("BobAccount");
        await testsUtils.shallPass({
          name: "mfl/players/create_and_link_player_collection.tx",
          signers: [bobAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: "mfl/players/withdraw_player.tx",
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, 1],
        });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
            data: { id: 1, from: aliceAdminAccountAddress },
          }),
        );
        expect(result.events[1]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
            data: { id: 1, to: bobAccountAddress },
          }),
        );
        const alicePlayersIds = await testsUtils.executeValidScript({
          name: "mfl/players/get_ids_in_collection.script",
          args: [aliceAdminAccountAddress],
        });
        expect(alicePlayersIds).toEqual([]);
        const bobPlayersIds = await testsUtils.executeValidScript({
          name: "mfl/players/get_ids_in_collection.script",
          args: [bobAccountAddress],
        });
        expect(bobPlayersIds).toEqual([1]);
      });
    });

    describe("batchWithdraw()", () => {
      test("should batch withdraw NFTs from a collection and batch deposit them in another collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        await MFLPlayerTestsUtils.createPlayerNFT(31);
        const bobAccountAddress = await getAccountAddress("BobAccount");
        await testsUtils.shallPass({
          name: "mfl/players/create_and_link_player_collection.tx",
          signers: [bobAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: "mfl/players/batch_withdraw_players.tx",
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, [1, 31]],
        });

        // assert
        expect(result.events).toHaveLength(8);
        expect(result.events).toEqual(
          expect.arrayContaining([
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
              data: { id: 1, from: aliceAdminAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
              data: { id: 31, from: aliceAdminAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
              data: { id: 1, to: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
              data: { id: 31, to: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
              data: { id: 1, from: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
              data: { id: 1, to: bobAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Withdraw`,
              data: { id: 31, from: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
              data: { id: 31, to: bobAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
          ]),
        );

        const alicePlayersIds = await testsUtils.executeValidScript({
          name: "mfl/players/get_ids_in_collection.script",
          args: [aliceAdminAccountAddress],
        });
        expect(alicePlayersIds).toEqual([]);
        const bobPlayersIds = await testsUtils.executeValidScript({
          name: "mfl/players/get_ids_in_collection.script",
          args: [bobAccountAddress],
        });
        expect(bobPlayersIds).toHaveLength(2);
        expect(bobPlayersIds).toEqual(expect.arrayContaining([1, 31]));
      });
    });

    describe("getIDs()", () => {
      test("should get the IDs in the collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(100022);
        await MFLPlayerTestsUtils.createPlayerNFT(1);
        await MFLPlayerTestsUtils.createPlayerNFT(89);

        // execute
        const ids = await testsUtils.executeValidScript({
          name: "mfl/players/get_ids_in_collection.script",
          args: [aliceAdminAccountAddress],
        });

        // assert
        expect(ids).toHaveLength(3);
        expect(ids).toEqual(expect.arrayContaining([100022, 1, 89]));
      });
    });

    describe("borrowNFT()", () => {
      test("should borrow a NFT in the collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        const playerID = 5;
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const playerFromCollection = await testsUtils.executeValidScript({
          code: `
            import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
            import MFLPlayer from "../../../../contracts/players/MFLPlayer.cdc"

            pub fun main(address: Address, playerID: UInt64): &NonFungibleToken.NFT {
                let playerCollectionRef = getAccount(address).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLPlayer.CollectionPublicPath).borrow()
                    ?? panic("Could not borrow the collection reference")
                let nftRef = playerCollectionRef.borrowNFT(id: playerID)
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
          uuid: expect.toBeNumber(),
        });
      });
    });

    describe("destroy", () => {
      test("should destroy a collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
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
        expect(result.events).toPartiallyContain({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Destroyed`,
          data: { id: 1 },
        });
        expect(result.events).toPartiallyContain({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Destroyed`,
          data: { id: 23 },
        });
      });
    });
  });

  describe("createEmptyCollection()", () => {
    test("should create an empty collection", async () => {
      // prepare
      const bobAccountAddress = await getAccountAddress("BobAccount");

      // execute
      await testsUtils.shallPass({
        name: "mfl/players/create_and_link_player_collection.tx",
        signers: [bobAccountAddress],
      });

      // assert
      await testsUtils.executeValidScript({
        name: "mfl/players/get_ids_in_collection.script",
        args: [bobAccountAddress],
      });
    });
  });

  describe("NFT", () => {
    describe("getViews()", () => {
      test("should get views types", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(100022);

        // execute
        const viewsTypes = await testsUtils.executeValidScript({
          name: "mfl/players/get_player_views_from_collection.script",
          args: [aliceAdminAccountAddress, 100022],
        });

        // assert
        expect(viewsTypes.map((viewType) => viewType.typeID)).toEqual(
          expect.arrayContaining([
            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
            `A.${testsUtils.sansPrefix(addressMap.MFLViews)}.MFLViews.PlayerDataViewV1`,
          ]),
        );
      });
    });

    describe("resolveView()", () => {
      test("should resolve Display view for a specific player", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(100022);

        // execute
        const playerDisplayView = await testsUtils.executeValidScript({
          name: "mfl/players/get_player_display_view_from_collection.script",
          args: [aliceAdminAccountAddress, 100022],
        });

        // assert
        expect(playerDisplayView).toEqual({
          name: "some name",
          description: "MFL Player #100022",
          thumbnail: "ipfs://QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm",
          owner: aliceAdminAccountAddress,
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`,
        });
      });

      test("should resolve Display view for all players", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(100022);
        await MFLPlayerTestsUtils.createPlayerNFT(100023);

        // execute
        const playersDisplayView = await testsUtils.executeValidScript({
          name: "mfl/players/get_players_display_view_from_collection.script",
          args: [aliceAdminAccountAddress, [100022, 100023]],
        });

        // assert
        expect(playersDisplayView).toEqual(
          expect.arrayContaining([
            {
              name: "some name",
              description: "MFL Player #100022",
              thumbnail: "ipfs://QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm",
              owner: aliceAdminAccountAddress,
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`,
            },
            {
              name: "some name",
              description: "MFL Player #100023",
              thumbnail: "ipfs://QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm",
              owner: aliceAdminAccountAddress,
              type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.NFT`,
            },
          ]),
        );
      });

      test("should resolve PlayerData view for a specific player", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        const playerID = 100022;
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const playerDataView = await testsUtils.executeValidScript({
          name: "mfl/players/get_player_data_view_from_collection.script",
          args: [aliceAdminAccountAddress, playerID],
        });

        // assert
        expect(playerDataView).toEqual({
          id: playerID,
          season: 1,
          thumbnail: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
          metadata: omit(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY, "longevity"),
        });
      });

      test("should resolve PlayerData view for all players", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        const playerID1 = 100022;
        const playerID2 = 100023;
        await MFLPlayerTestsUtils.createPlayerNFT(playerID1);
        await MFLPlayerTestsUtils.createPlayerNFT(playerID2);

        // execute
        const playersDataView = await testsUtils.executeValidScript({
          name: "mfl/players/get_players_data_view_from_collection.script",
          args: [aliceAdminAccountAddress, [100022, 100023]],
        });

        // assert
        expect(playersDataView).toEqual(
          expect.arrayContaining([
            {
              id: playerID1,
              season: 1,
              thumbnail: {
                cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
                path: null,
              },
              metadata: omit(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY, "longevity"),
            },
            {
              id: playerID2,
              season: 1,
              thumbnail: {
                cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
                path: null,
              },
              metadata: omit(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY, "longevity"),
            },
          ]),
        );
      });
    });

    describe("destroy()", () => {
      test("should destroy the NFT", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        await MFLPlayerTestsUtils.createPlayerNFT(100022);

        // execute
        const signers = [aliceAdminAccountAddress];
        const args = [100022];
        const result = await testsUtils.shallPass({ name: "mfl/players/destroy_player.tx", args, signers });

        // assert
        expect(result.events).toPartiallyContain({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Destroyed`,
          data: { id: 100022 },
        });
        const error = await testsUtils.executeFailingScript({
          name: "mfl/players/get_player_data_view_from_collection.script",
          args: [aliceAdminAccountAddress, 100022],
        });
        expect(error.message).toContain("unexpectedly found nil while forcing an Optional value");
      });
    });
  });

  describe("getPlayerData()", () => {
    test("should get player data", async () => {
      // prepare
      await MFLPlayerTestsUtils.createPlayerAdmin("AliceAdminAccount", "AliceAdminAccount");
      const playerID = 4;
      await MFLPlayerTestsUtils.createPlayerNFT(playerID);

      // execute
      const playerData = await testsUtils.executeValidScript({
        name: "mfl/players/get_player_data.script",
        args: [playerID],
      });

      // assert
      expect(playerData).toEqual({
        id: playerID,
        metadata: MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY,
        season: 1,
        image: {
          cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
          path: null,
        },
      });
    });

    test("should return nil when getting player data for an unknown player", async () => {
      // prepare

      // execute
      const playerData = await testsUtils.executeValidScript({
        name: "mfl/players/get_player_data.script",
        args: [4],
      });

      // assert
      expect(playerData).toBeNull();
    });

    test("should throw an error when updating player metadata", async () => {
      // prepare
      await MFLPlayerTestsUtils.createPlayerAdmin("AliceAdminAccount", "AliceAdminAccount");
      await MFLPlayerTestsUtils.createPlayerNFT(1);

      // execute
      const error = await testsUtils.shallRevert({
        code: ERROR_UPDATE_PLAYER_METADATA,
        args: [1],
      });

      // assert
      expect(error).toContain("cannot access `metadata`: field has contract access");
    });
  });

  describe("PlayerAdmin", () => {
    describe("mintPlayer()", () => {
      test("should mint a player", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );

        // execute
        const signers = [aliceAdminAccountAddress];
        const playerID = 1201;
        const args = [
          playerID,
          1,
          "QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm",
          ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY),
          aliceAdminAccountAddress,
        ];
        const result = await testsUtils.shallPass({ name: "mfl/players/mint_player.tx", args, signers });

        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Minted`,
            data: { id: playerID },
          }),
        );
        expect(result.events[1]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Deposit`,
            data: { id: playerID, to: aliceAdminAccountAddress },
          }),
        );
        const playerData = await testsUtils.executeValidScript({
          name: "mfl/players/get_player_data.script",
          args: [playerID],
        });
        expect(playerData).toEqual({
          id: playerID,
          metadata: MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY,
          season: 1,
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
        });
        const totalSupply = await testsUtils.executeValidScript({
          name: "mfl/players/get_players_total_supply.script",
        });
        expect(totalSupply).toBe(1);
        const playerFromCollection = await testsUtils.executeValidScript({
          code: BORROW_VIEW_RESOLVER,
          args: [aliceAdminAccountAddress, playerID],
        });
        expect(playerFromCollection).toEqual({
          id: playerID,
          season: 1,
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
          uuid: expect.toBeNumber(),
        });
      });

      test("should panic when minting a player id already minted", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );

        // execute
        const signers = [aliceAdminAccountAddress];
        const playerID = 1201;
        const args = [
          playerID,
          1,
          "QmbdfaUn6itAQbEgf8nLLZok6jX5BcqkZJR3dVrd3hLHKm",
          ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY),
          aliceAdminAccountAddress,
        ];
        await testsUtils.shallPass({ name: "mfl/players/mint_player.tx", args, signers });
        const error = await testsUtils.shallRevert({ name: "mfl/players/mint_player.tx", args, signers });

        // assert
        expect(error).toContain("Player already exists");
      });
    });

    describe("updatePlayerMetadata()", () => {
      test("should update player metadata", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        const signers = [aliceAdminAccountAddress];
        const playerID = 1200;
        await MFLPlayerTestsUtils.createPlayerNFT(playerID);

        // execute
        const updatedMetadata = { ...MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY };
        updatedMetadata.positions = ["ST", "RW", "LW"];
        updatedMetadata.overall = 99;
        const result = await testsUtils.shallPass({
          name: "mfl/players/update_player_metadata.tx",
          args: [playerID, ...Object.values(updatedMetadata)],
          signers,
        });

        // assert
        const playerData = await testsUtils.executeValidScript({
          name: "mfl/players/get_player_data.script",
          args: [playerID],
        });
        expect(playerData).toEqual({
          id: playerID,
          metadata: updatedMetadata,
          season: 1,
          image: {
            cid: MFLPlayerTestsUtils.PLAYER_DATA.folderCID,
            path: null,
          },
        });
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLPlayer)}.MFLPlayer.Updated`,
            data: { id: playerID },
          }),
        );
      });

      test("should panic when updating a player metadata for an unknown player", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        const signers = [aliceAdminAccountAddress];

        // execute
        const error = await testsUtils.shallRevert({
          name: "mfl/players/update_player_metadata.tx",
          args: [1201, ...Object.values(MFLPlayerTestsUtils.PLAYER_METADATA_DICTIONARY)],
          signers,
        });

        // assert
        expect(error).toContain("Data not found");
      });
    });

    describe("createPlayerAdmin()", () => {
      test("should create a player admin", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLPlayerTestsUtils.createPlayerAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
        );
        const bobAccountAddress = await getAccountAddress("BobAccount");
        const jackAccountAddress = await getAccountAddress("JackAccount");

        // execute
        const signers = [aliceAdminAccountAddress, bobAccountAddress];
        await testsUtils.shallPass({
          name: "mfl/players/create_player_admin.tx",
          signers,
        });

        // assert
        // bob must now be able to create another player admin
        await testsUtils.shallPass({
          name: "mfl/players/create_player_admin.tx",
          signers: [bobAccountAddress, jackAccountAddress],
        });
      });

      test("should panic when trying to create a player admin with a non admin account", async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress("BobAccount");
        const jackAccountAddress = await getAccountAddress("JackAccount");

        // execute
        const signers = [bobAccountAddress, jackAccountAddress];
        const error = await testsUtils.shallRevert({
          name: "mfl/players/create_player_admin.tx",
          signers,
        });

        // assert
        expect(error).toContain("Could not borrow player admin ref");
      });
    });
  });
});

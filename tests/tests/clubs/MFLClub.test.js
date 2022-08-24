import { emulator, getAccountAddress } from "flow-js-testing";
import { MFLClubTestsUtils } from "./_utils/MFLClubTests.utils";
import { testsUtils } from "../_utils/tests.utils";
import * as matchers from "jest-extended";

expect.extend(matchers);
jest.setTimeout(40000);

describe("MFLClub", () => {
  let addressMap = null;

  beforeEach(async () => {
    await testsUtils.initEmulator(8084);
    addressMap = await MFLClubTestsUtils.deployMFLClubContract("AliceAdminAccount");
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe("totalSupply", () => {
    test("should be able to get the total supply for clubs", async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: "mfl/clubs/get_clubs_total_supply.script",
      });
      expect(totalSupply).toBe(0);
    });
  });

  describe("squadsTotalSupply", () => {
    test("should be able to get the total supply for squads", async () => {
      const totalSupply = await testsUtils.executeValidScript({
        name: "mfl/clubs/squads/get_squads_total_supply.script",
      });
      expect(totalSupply).toBe(0);
    });
  });

  describe("clubsDatas", () => {
    test("should not be able to get directly clubsDatas", async () => {
      // prepare

      // execute
      const error = await testsUtils.executeFailingScript({
        code: `
          import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
          pub fun main(): {UInt64: MFLClub.ClubData} {
              return MFLClub.clubsDatas
          }
        `,
        addressMap,
      });

      // assert
      expect(error.message).toContain("field has private access");
    });
  });

  describe("squadsDatas", () => {
    test("should not be able to get directly squadsDatas", async () => {
      // prepare

      // execute
      const error = await testsUtils.executeFailingScript({
        code: `
          import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
          pub fun main(): {UInt64: MFLClub.SquadData} {
              return MFLClub.squadsDatas
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
      test("should withdraw a club NFT from a collection and deposit it in another collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        await MFLClubTestsUtils.createClubNFT(1, 1);
        const bobAccountAddress = await getAccountAddress("BobAccount");
        await testsUtils.shallPass({
          name: "mfl/clubs/create_and_link_club_collection.tx",
          signers: [bobAccountAddress],
        });
        // execute
        const result = await testsUtils.shallPass({
          name: "mfl/clubs/withdraw_club.tx",
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, 1],
        });
        // assert
        expect(result.events).toHaveLength(2);
        expect(result.events[0]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Withdraw`,
            data: { id: 1, from: aliceAdminAccountAddress },
          }),
        );
        expect(result.events[1]).toEqual(
          expect.objectContaining({
            type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Deposit`,
            data: { id: 1, to: bobAccountAddress },
          }),
        );
        const aliceClubsIds = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_ids_in_collection.script",
          args: [aliceAdminAccountAddress],
        });
        expect(aliceClubsIds).toEqual([]);
        const bobClubsIds = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_ids_in_collection.script",
          args: [bobAccountAddress],
        });
        expect(bobClubsIds).toEqual([1]);
      });
    });

    describe("batchWithdraw()", () => {
      test("should batch withdraw clubs NFTs from a collection and batch deposit them in another collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        await MFLClubTestsUtils.createClubNFT(1, 1);
        await MFLClubTestsUtils.createClubNFT(2, 2);
        const bobAccountAddress = await getAccountAddress("BobAccount");
        await testsUtils.shallPass({
          name: "mfl/clubs/create_and_link_club_collection.tx",
          signers: [bobAccountAddress],
        });

        // execute
        const result = await testsUtils.shallPass({
          name: "mfl/clubs/batch_withdraw_clubs.tx",
          signers: [aliceAdminAccountAddress],
          args: [bobAccountAddress, [1, 2]],
        });

        // assert
        expect(result.events).toHaveLength(8);
        expect(result.events).toEqual(
          expect.arrayContaining([
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Withdraw`,
              data: { id: 1, from: aliceAdminAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Withdraw`,
              data: { id: 2, from: aliceAdminAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Deposit`,
              data: { id: 1, to: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Deposit`,
              data: { id: 2, to: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Withdraw`,
              data: { id: 1, from: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Deposit`,
              data: { id: 1, to: bobAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Withdraw`,
              data: { id: 2, from: null },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Deposit`,
              data: { id: 2, to: bobAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
          ]),
        );

        const aliceClubsIds = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_ids_in_collection.script",
          args: [aliceAdminAccountAddress],
        });
        expect(aliceClubsIds).toEqual([]);
        const bobClubsIds = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_ids_in_collection.script",
          args: [bobAccountAddress],
        });
        expect(bobClubsIds).toHaveLength(2);
        expect(bobClubsIds).toEqual(expect.arrayContaining([1, 2]));
      });
    });

    describe("getIDs()", () => {
      test("should get the IDs in the collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        await MFLClubTestsUtils.createClubNFT(10, 1);
        await MFLClubTestsUtils.createClubNFT(42, 2);
        await MFLClubTestsUtils.createClubNFT(101, 3);

        // execute
        const ids = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_ids_in_collection.script",
          args: [aliceAdminAccountAddress],
        });

        // assert
        expect(ids).toHaveLength(3);
        expect(ids).toEqual(expect.arrayContaining([10, 42, 101]));
      });
    });

    describe("borrowNFT()", () => {
      test("should borrow a NFT in the collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const clubID = 101;
        const squadID = 1;
        await MFLClubTestsUtils.createClubNFT(clubID, squadID);

        // execute
        const clubFromCollection = await testsUtils.executeValidScript({
          code: `
              import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
              import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
              pub fun main(address: Address, clubID: UInt64): &NonFungibleToken.NFT {
                  let clubCollectionRef = getAccount(address).getCapability<&{NonFungibleToken.CollectionPublic}>(MFLClub.CollectionPublicPath).borrow()
                      ?? panic("Could not borrow the collection reference")
                  let nftRef = clubCollectionRef.borrowNFT(id: clubID)
                  return nftRef
              }
            `,
          args: [aliceAdminAccountAddress, clubID],
        });

        // assert
        expect(clubFromCollection).toEqual({
          id: clubID,
          squads: {
            1: {
              id: 1,
              clubID: clubID,
              type: "squadType",
              metadata: {},
              uuid: expect.toBeNumber(),
            },
          },
          metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
          uuid: expect.toBeNumber(),
        });
      });
    });

    describe("destroy", () => {
      test("should destroy a collection", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        await MFLClubTestsUtils.createClubNFT(1, 1);
        await MFLClubTestsUtils.createClubNFT(2, 2);

        // execute
        const result = await testsUtils.shallPass({
          code: `
              import MFLClub from "../../../contracts/clubs/MFLClub.cdc"
              
              transaction() {
              
                  prepare(acct: AuthAccount) {
                      let collection <- acct.load<@MFLClub.Collection>(from: MFLClub.CollectionStoragePath)!
                      destroy collection
                  }
              }
            `,
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(4);
        expect(result.events).toEqual(
          expect.arrayContaining([
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubDestroyed`,
              data: { id: 1 },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubDestroyed`,
              data: { id: 2 },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadDestroyed`,
              data: { id: 1 },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadDestroyed`,
              data: { id: 2 },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
          ]),
        );
      });
    });

    describe("createEmptyCollection()", () => {
      test("should create an empty collection", async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress("BobAccount");

        // execute
        await testsUtils.shallPass({
          name: "mfl/clubs/create_and_link_club_collection.tx",
          signers: [bobAccountAddress],
        });

        // assert
        await testsUtils.executeValidScript({
          name: "mfl/clubs/get_ids_in_collection.script",
          args: [bobAccountAddress],
        });
      });
    });

    describe("Club NFT", () => {
      describe("getViews()", () => {
        test("should get views types", async () => {
          // prepare
          const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
            "AliceAdminAccount",
            "AliceAdminAccount",
            true,
            true,
          );
          await MFLClubTestsUtils.createClubNFT(1, 1);

          // execute
          const viewsTypes = await testsUtils.executeValidScript({
            name: "mfl/clubs/get_club_views_from_collection.script",
            args: [aliceAdminAccountAddress, 1],
          });

          // assert
          expect(viewsTypes).toHaveLength(5);
          expect(viewsTypes.map((viewType) => viewType.typeID)).toEqual(
            expect.arrayContaining([
              `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
              `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Royalties`,
              `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionDisplay`,
              `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionData`,
              `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.ExternalURL`,
            ]),
          );
        });
      });
    });
  });
});

import { emulator, getAccountAddress } from "flow-js-testing";
import { MFLClubTestsUtils } from "./_utils/MFLClubTests.utils";
import { testsUtils } from "../_utils/tests.utils";
import * as matchers from "jest-extended";
import { ERROR_UPDATE_CLUB_METADATA } from "./_transactions/error_update_club_metadata.tx";
import { ERROR_UPDATE_SQUAD_METADATA } from "./_transactions/error_update_squad_metadata.tx";
import { UPDATE_CLUB_METADATA } from "./_transactions/update_club_metadata.tx";
import { UPDATE_SQUAD_METADATA } from "./_transactions/update_squad_metadata.tx";
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

    // describe(() => {
    //   //TODO foundClub()
    // });

    // describe(() => {
    //   //TODO requestClubInfoUpdate()
    // });

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

      describe("resolveView()", () => {
        test("should resolve Display view for a specific club", async () => {
          // prepare
          const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
            "AliceAdminAccount",
            "AliceAdminAccount",
            true,
            true,
          );
          const clubId = 1000;
          await MFLClubTestsUtils.createClubNFT(clubId, 1);

          // execute
          const clubDisplayView = await testsUtils.executeValidScript({
            name: "mfl/clubs/get_club_display_view_from_collection.script",
            args: [aliceAdminAccountAddress, clubId],
          });

          // assert
          expect(clubDisplayView).toEqual({
            name: "",
            description: "",
            thumbnail: `https://d11e2517uhbeau.cloudfront.net/clubs/${clubId}/thumbnail.png`,
            owner: aliceAdminAccountAddress,
            type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
          });
        });

        test("should resolve Display view for all clubs", async () => {
          // prepare
          const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
            "AliceAdminAccount",
            "AliceAdminAccount",
            true,
            true,
          );
          const clubId1 = 450;
          const clubId2 = 578;
          await MFLClubTestsUtils.createClubNFT(clubId1, 1);
          await MFLClubTestsUtils.createClubNFT(clubId2, 2);

          // execute
          const clubsDisplayView = await testsUtils.executeValidScript({
            name: "mfl/clubs/get_clubs_display_view_from_collection.script",
            args: [aliceAdminAccountAddress, [clubId1, clubId2]],
          });

          // assert
          expect(clubsDisplayView).toEqual(
            expect.arrayContaining([
              {
                name: "",
                description: "",
                thumbnail: `https://d11e2517uhbeau.cloudfront.net/clubs/${clubId1}/thumbnail.png`,
                owner: aliceAdminAccountAddress,
                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
              },
              {
                name: "",
                description: "",
                thumbnail: `https://d11e2517uhbeau.cloudfront.net/clubs/${clubId2}/thumbnail.png`,
                owner: aliceAdminAccountAddress,
                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
              },
            ]),
          );
        });
      });

      describe("destroy()", () => {
        test("should destroy the NFT", async () => {
          // prepare
          const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
            "AliceAdminAccount",
            "AliceAdminAccount",
            true,
            true,
          );
          const clubId = 450;
          const squadId = 1;
          await MFLClubTestsUtils.createClubNFT(clubId, squadId);

          // execute
          const signers = [aliceAdminAccountAddress];
          const args = [clubId];
          const result = await testsUtils.shallPass({ name: "mfl/clubs/destroy_club.tx", args, signers });

          // assert
          expect(result.events).toHaveLength(3);
          expect(result.events).toEqual(
            expect.arrayContaining([
              {
                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Withdraw`,
                data: { id: clubId, from: aliceAdminAccountAddress },
                eventIndex: expect.any(Number),
                transactionId: expect.any(String),
                transactionIndex: expect.any(Number),
              },
              {
                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubDestroyed`,
                data: { id: clubId },
                eventIndex: expect.any(Number),
                transactionId: expect.any(String),
                transactionIndex: expect.any(Number),
              },
              {
                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadDestroyed`,
                data: { id: squadId },
                eventIndex: expect.any(Number),
                transactionId: expect.any(String),
                transactionIndex: expect.any(Number),
              },
            ]),
          );
          const error = await testsUtils.executeFailingScript({
            name: "mfl/clubs/get_club_display_view_from_collection.script",
            args: [aliceAdminAccountAddress, clubId],
          });
          expect(error.message).toContain("unexpectedly found nil while forcing an Optional value");
        });
      });
    });
  });

  describe("getClubData()", () => {
    test("should get club data for a not founded club", async () => {
      // prepare
      await MFLClubTestsUtils.createClubAndSquadAdmin("AliceAdminAccount", "AliceAdminAccount", true, true);
      const clubId = 42;
      const squadId = 101;
      await MFLClubTestsUtils.createClubNFT(clubId, squadId);

      // execute
      const clubData = await testsUtils.executeValidScript({
        name: "mfl/clubs/get_club_data.script",
        args: [clubId],
      });

      // assert
      expect(clubData).toEqual({
        id: clubId,
        metadata: {},
        status: { rawValue: 0 }, // status = NOT_FOUNDED
        squadsIDs: [squadId],
      });
    });

    test("should get club data for a founded club", async () => {
      // prepare
      await MFLClubTestsUtils.createClubAndSquadAdmin("AliceAdminAccount", "AliceAdminAccount", true, true);
      const clubId = 42;
      const clubName = "Wax FC";
      const clubDescription = "Hello world";
      const squadId = 101;
      await MFLClubTestsUtils.createClubNFT(clubId, squadId);
      await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription);

      // execute
      const clubData = await testsUtils.executeValidScript({
        name: "mfl/clubs/get_club_data.script",
        args: [clubId],
      });

      // assert
      expect(clubData).toEqual({
        id: clubId,
        metadata: {
          name: clubName,
          description: clubDescription,
          foundationDate: expect.any(String),
          ...MFLClubTestsUtils.FOUNDATION_LICENSE,
        },
        status: { rawValue: 1 }, // status = PENDING_VALIDATION
        squadsIDs: [squadId],
      });
    });

    test("should return nil when getting club data for an unknown club", async () => {
      // prepare

      // execute
      const clubData = await testsUtils.executeValidScript({
        name: "mfl/clubs/get_club_data.script",
        args: [4],
      });

      // assert
      expect(clubData).toBeNull();
    });

    test("should throw an error when updating club metadata", async () => {
      // prepare
      await MFLClubTestsUtils.createClubAndSquadAdmin("AliceAdminAccount", "AliceAdminAccount", true, true);
      const clubId = 1;
      await MFLClubTestsUtils.createClubNFT(clubId, 1);

      // execute
      const error = await testsUtils.shallRevert({
        code: ERROR_UPDATE_CLUB_METADATA,
        args: [clubId],
      });

      // assert
      expect(error).toContain("cannot access `metadata`: field has private access");
    });
  });

  describe("getSquadData()", () => {
    test("should get squad data for a not founded club", async () => {
      // prepare
      await MFLClubTestsUtils.createClubAndSquadAdmin("AliceAdminAccount", "AliceAdminAccount", true, true);
      const clubId = 42;
      const squadId = 101;
      await MFLClubTestsUtils.createClubNFT(clubId, squadId);

      // execute
      const clubData = await testsUtils.executeValidScript({
        name: "mfl/clubs/squads/get_squad_data.script",
        args: [squadId],
      });

      // assert
      expect(clubData).toEqual({
        id: squadId,
        clubID: clubId,
        type: "squadType",
        status: { rawValue: 0 }, // status = ACTIVE
        metadata: {},
        competitionsMemberships: {},
      });
    });

    test("should return nil when getting squad data for an unknown squad", async () => {
      // prepare

      // execute
      const squadData = await testsUtils.executeValidScript({
        name: "mfl/clubs/squads/get_squad_data.script",
        args: [4],
      });

      // assert
      expect(squadData).toBeNull();
    });

    test("should throw an error when updating squad metadata", async () => {
      // prepare
      await MFLClubTestsUtils.createClubAndSquadAdmin("AliceAdminAccount", "AliceAdminAccount", true, true);
      const squadId = 1;
      await MFLClubTestsUtils.createClubNFT(1, squadId);

      // execute
      const error = await testsUtils.shallRevert({
        code: ERROR_UPDATE_SQUAD_METADATA,
        args: [squadId],
      });

      // assert
      expect(error).toContain("cannot access `metadata`: field has private access");
    });
  });

  describe("ClubAdmin", () => {
    describe("mintClub()", () => {
      test("should mint a club", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const clubId = 1;
        const squadId = 1;

        // execute
        const result = await MFLClubTestsUtils.createClubNFT(clubId, squadId);

        // assert
        expect(result.events).toHaveLength(3);
        expect(result.events).toEqual(
          expect.arrayContaining([
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadMinted`,
              data: { id: squadId },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubMinted`,
              data: { id: clubId },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
            {
              type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.Deposit`,
              data: { id: clubId, to: aliceAdminAccountAddress },
              eventIndex: expect.any(Number),
              transactionId: expect.any(String),
              transactionIndex: expect.any(Number),
            },
          ]),
        );
        const clubData = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_club_data.script",
          args: [clubId],
        });
        const squadData = await testsUtils.executeValidScript({
          name: "mfl/clubs/squads/get_squad_data.script",
          args: [squadId],
        });
        const totalSupply = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_clubs_total_supply.script",
        });
        const squadsTotalSupply = await testsUtils.executeValidScript({
          name: "mfl/clubs/squads/get_squads_total_supply.script",
        });
        expect(clubData).toEqual({
          id: clubId,
          metadata: {},
          status: { rawValue: 0 }, // status = NOT_FOUNDED
          squadsIDs: [squadId],
        });
        expect(squadData).toEqual({
          id: squadId,
          clubID: clubId,
          type: "squadType",
          status: { rawValue: 0 }, // status = ACTIVE
          metadata: {},
          competitionsMemberships: {},
        });
        expect(totalSupply).toBe(1);
        expect(squadsTotalSupply).toBe(1);
      });

      test("should panic when minting a club id already minted", async () => {
        // prepare
        await MFLClubTestsUtils.createClubAndSquadAdmin("AliceAdminAccount", "AliceAdminAccount", true, true);
        const clubId = 1;

        // execute
        await MFLClubTestsUtils.createClubNFT(clubId, 1);
        const error = await MFLClubTestsUtils.createClubNFT(clubId, 2, false);

        // assert
        expect(error).toContain("Club already exists");
      });
    });

    describe("updateClubStatus()", () => {
      test("should update club status", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const clubId = 1;
        const squadId = 10;
        const statusRawValue = 2; // rawValue 2 = FOUNDED status
        await MFLClubTestsUtils.createClubNFT(clubId, squadId);

        // execute
        const result = await testsUtils.shallPass({
          name: "mfl/clubs/update_club_status.tx",
          args: [clubId, statusRawValue],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubStatusUpdated`,
          data: { id: clubId, status: statusRawValue },
          eventIndex: expect.any(Number),
          transactionId: expect.any(String),
          transactionIndex: expect.any(Number),
        });
        const clubData = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_club_data.script",
          args: [clubId],
        });
        expect(clubData).toEqual({
          id: clubId,
          status: { rawValue: statusRawValue },
          squadsIDs: [squadId],
          metadata: {},
        });
      });

      test("should throw an error when club does not exist", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const statusRawValue = 2; // rawValue 2 = FOUNDED status

        // execute
        const error = await testsUtils.shallRevert({
          name: "mfl/clubs/update_club_status.tx",
          args: [208, statusRawValue],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain("Club data not found");
      });
    });

    describe("updateClubMetadata()", () => {
      test("should update club metadata", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const clubId = 1;
        const squadId = 10;
        const updatedClubName = "New Club Name";
        const updatedClubDescription = "New Club Description";
        await MFLClubTestsUtils.createClubNFT(clubId, squadId);

        // execute
        const result = await testsUtils.shallPass({
          code: UPDATE_CLUB_METADATA,
          args: [clubId, updatedClubName, updatedClubDescription],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubMetadataUpdated`,
          data: { id: clubId },
          eventIndex: expect.any(Number),
          transactionId: expect.any(String),
          transactionIndex: expect.any(Number),
        });
        const clubData = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_club_data.script",
          args: [clubId],
        });
        expect(clubData).toEqual({
          id: clubId,
          status: { rawValue: 0 },
          squadsIDs: [squadId],
          metadata: { name: updatedClubName, description: updatedClubDescription },
        });
      });

      test("should throw an error when club does not exist", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );

        // execute
        const error = await testsUtils.shallRevert({
          code: UPDATE_CLUB_METADATA,
          args: [208, "New name", "New description"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain("Club data not found");
      });
    });

    describe("updateClubSquadsIDs()", () => {
      test("should update club squads ids", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const clubId = 1;
        const squadId = 10;
        await MFLClubTestsUtils.createClubNFT(clubId, squadId);

        // execute
        const result = await testsUtils.shallPass({
          name: "mfl/clubs/update_club_squads_ids.tx",
          args: [clubId, [squadId, 42]],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubSquadsIDsUpdated`,
          data: { id: clubId, squadsIDs: [squadId, 42] },
          eventIndex: expect.any(Number),
          transactionId: expect.any(String),
          transactionIndex: expect.any(Number),
        });
        const clubData = await testsUtils.executeValidScript({
          name: "mfl/clubs/get_club_data.script",
          args: [clubId],
        });
        expect(clubData).toEqual({
          id: clubId,
          status: { rawValue: 0 },
          squadsIDs: [squadId, 42],
          metadata: {},
        });
      });

      test("should throw an error when club does not exist", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );

        // execute
        const error = await testsUtils.shallRevert({
          name: "mfl/clubs/update_club_squads_ids.tx",
          args: [208, [42]],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain("Club data not found");
      });
    });

    describe("createClubAdmin()", () => {
      test("should create a club admin", async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress("AliceAdminAccount");
        const bobAccountAddress = await getAccountAddress("BobAccount");
        const jackAccountAddress = await getAccountAddress("JackAccount");

        // execute
        const signers = [aliceAdminAccountAddress, bobAccountAddress];
        await testsUtils.shallPass({
          name: "mfl/clubs/create_club_admin.tx",
          signers,
        });

        // assert
        // bob must now be able to create another club admin
        await testsUtils.shallPass({
          name: "mfl/clubs/create_club_admin.tx",
          signers: [bobAccountAddress, jackAccountAddress],
        });
      });

      test("should panic when trying to create a club admin with a non admin account", async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress("BobAccount");
        const jackAccountAddress = await getAccountAddress("JackAccount");

        // execute
        const signers = [bobAccountAddress, jackAccountAddress];
        const error = await testsUtils.shallRevert({
          name: "mfl/clubs/create_club_admin.tx",
          signers,
        });

        // assert
        expect(error).toContain("Could not borrow club admin ref");
      });
    });
  });

  describe("SquadAdmin", () => {
    describe("updateSquadMetadata()", () => {
      test("should update squad metadata", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );
        const clubId = 1;
        const squadId = 10;
        const updatedSquadName = "My squad";
        const updatedSquadDescription = "My squad description";
        await MFLClubTestsUtils.createClubNFT(clubId, squadId);

        // execute
        const result = await testsUtils.shallPass({
          code: UPDATE_SQUAD_METADATA,
          args: [squadId, updatedSquadName, updatedSquadDescription],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(result.events).toHaveLength(1);
        expect(result.events[0]).toEqual({
          type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadMetadataUpdated`,
          data: { id: squadId },
          eventIndex: expect.any(Number),
          transactionId: expect.any(String),
          transactionIndex: expect.any(Number),
        });
        const squadData = await testsUtils.executeValidScript({
          name: "mfl/clubs/squads/get_squad_data.script",
          args: [squadId],
        });
        expect(squadData).toEqual({
          id: squadId,
          clubID: clubId,
          type: "squadType",
          status: { rawValue: 0 },
          metadata: {},
          competitionsMemberships: {},
        });
      });

      test("should throw an error when squad does not exist", async () => {
        // prepare
        const aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
          "AliceAdminAccount",
          "AliceAdminAccount",
          true,
          true,
        );

        // execute
        const error = await testsUtils.shallRevert({
          code: UPDATE_SQUAD_METADATA,
          args: [208, "New name", "New description"],
          signers: [aliceAdminAccountAddress],
        });

        // assert
        expect(error).toContain("Squad data not found");
      });
    });

    describe("createSquadAdmin()", () => {
      test("should create a squad admin", async () => {
        // prepare
        const aliceAdminAccountAddress = await getAccountAddress("AliceAdminAccount");
        const bobAccountAddress = await getAccountAddress("BobAccount");
        const jackAccountAddress = await getAccountAddress("JackAccount");

        // execute
        const signers = [aliceAdminAccountAddress, bobAccountAddress];
        await testsUtils.shallPass({
          name: "mfl/clubs/squads/create_squad_admin.tx",
          signers,
        });

        // assert
        // bob must now be able to create another squad admin
        await testsUtils.shallPass({
          name: "mfl/clubs/squads/create_squad_admin.tx",
          signers: [bobAccountAddress, jackAccountAddress],
        });
      });

      test("should panic when trying to create a squad admin with a non admin account", async () => {
        // prepare
        const bobAccountAddress = await getAccountAddress("BobAccount");
        const jackAccountAddress = await getAccountAddress("JackAccount");

        // execute
        const signers = [bobAccountAddress, jackAccountAddress];
        const error = await testsUtils.shallRevert({
          name: "mfl/clubs/squads/create_squad_admin.tx",
          signers,
        });

        // assert
        expect(error).toContain("Could not borrow squad admin ref");
      });
    });
  });
});

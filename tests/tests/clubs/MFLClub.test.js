import {emulator, getAccountAddress} from '@onflow/flow-js-testing';
import {MFLClubTestsUtils} from './_utils/MFLClubTests.utils';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import {ERROR_UPDATE_CLUB_METADATA} from './_transactions/error_update_club_metadata.tx';
import {ERROR_UPDATE_SQUAD_METADATA} from './_transactions/error_update_squad_metadata.tx';
import {UPDATE_CLUB_METADATA} from './_transactions/update_club_metadata.tx';
import {UPDATE_SQUAD_METADATA} from './_transactions/update_squad_metadata.tx';
import {ADD_SQUAD_COMPETITION_MEMBERSHIP} from './_transactions/add_squad_competition_membership.tx';
import {UPDATE_SQUAD_COMPETITION_MEMBERSHIP} from './_transactions/update_squad_competition_membership.tx';
import {GET_CLUB_SERIAL_VIEW} from './_scripts/get_club_serial_view.script';
import {GET_CLUB_ROYALTIES_VIEW} from './_scripts/get_club_royalties_view.script';
import {WITHDRAW_CLUB_FROM_GIVEN_ADDRESS} from './_transactions/withdraw_club_from_given_address_malicious.tx';
import {WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2} from './_transactions/withdraw_club_from_given_address_v2_malicious.tx';
import {
    BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS,
} from './_transactions/batch_withdraw_club_from_given_address_malicious.tx';
import {
    BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2,
} from './_transactions/batch_withdraw_club_from_given_address_malicious_v2.tx';
import {WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V3} from './_transactions/withdraw_club_from_given_address_v3_malicious.tx';
import {FOUND_CLUB_MALICIOUS} from './_transactions/found_club_malicious.tx';
import {REQUEST_CLUB_INFO_UPDATE_MALICIOUS} from './_transactions/request_club_info_update_malicious.tx';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLClub', () => {
    let addressMap = null;
    let aliceAdminAccountAddress = null;

    beforeEach(async () => {
        await testsUtils.initEmulator();
        addressMap = await MFLClubTestsUtils.deployMFLClubContract('AliceAdminAccount');
        aliceAdminAccountAddress = await MFLClubTestsUtils.createClubAndSquadAdmin(
            'AliceAdminAccount',
            'AliceAdminAccount',
            true,
            true,
        );
    });

    afterEach(async () => {
        await emulator.stop();
    });

    describe('totalSupply', () => {
        test('should be able to get the total supply for clubs', async () => {
            const totalSupply = await testsUtils.executeValidScript({
                name: 'mfl/clubs/get_clubs_total_supply.script',
            });
            expect(totalSupply).toBe('0');
        });
    });

    describe('squadsTotalSupply', () => {
        test('should be able to get the total supply for squads', async () => {
            const totalSupply = await testsUtils.executeValidScript({
                name: 'mfl/clubs/squads/get_squads_total_supply.script',
            });
            expect(totalSupply).toBe('0');
        });
    });

    describe('clubsDatas', () => {
        test('should not be able to get directly clubsDatas', async () => {
            // prepare

            // execute
            const error = await testsUtils.executeFailingScript({
                code: `
          import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
          access(all)
          fun main(): {UInt64: MFLClub.ClubData} {
              return MFLClub.clubsDatas
          }
        `,
                addressMap,
            });

            // assert
            expect(error.message).toContain('cannot access `clubsDatas`: field requires `self` authorization');
        });
    });

    describe('squadsDatas', () => {
        test('should not be able to get directly squadsDatas', async () => {
            // prepare

            // execute
            const error = await testsUtils.executeFailingScript({
                code: `
          import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
          access(all)
          fun main(): {UInt64: MFLClub.SquadData} {
              return MFLClub.squadsDatas
          }
        `,
                addressMap,
            });

            // assert
            expect(error.message).toContain('cannot access `squadsDatas`: field requires `self` authorization');
        });
    });

    describe('Collection', () => {
        describe('withdraw() / deposit()', () => {
            test('should withdraw a club NFT from a collection and deposit it in another collection', async () => {
                // prepare
                await MFLClubTestsUtils.createClubNFT('1', '1');
                const bobAccountAddress = await getAccountAddress('BobAccount');
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_and_link_club_collection.tx',
                    signers: [bobAccountAddress],
                });
                // execute
                const result = await testsUtils.shallPass({
                    name: 'mfl/clubs/withdraw_club.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [bobAccountAddress, '1'],
                });

                // assert
                const expectedEvents = [
                    ...testsUtils.createExpectedWithdrawEvent('MFLClub', '1', aliceAdminAccountAddress),
                    ...testsUtils.createExpectedDepositedEvent('MFLClub', '1', bobAccountAddress),
                ]
                expect(result.events).toHaveLength(expectedEvents.length);
                expect(result.events[0]).toEqual(expectedEvents[0]);
                expect(result.events[1]).toEqual(expectedEvents[1]);
                expect(result.events[2]).toEqual(expectedEvents[2]);
                expect(result.events[3]).toEqual(expectedEvents[3]);

                const aliceClubsIds = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_ids_in_collection.script',
                    args: [aliceAdminAccountAddress],
                });
                expect(aliceClubsIds).toEqual([]);
                const bobClubsIds = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_ids_in_collection.script',
                    args: [bobAccountAddress],
                });
                expect(bobClubsIds).toEqual(['1']);
            });

            test('should not be able to withdraw a club NFT from a collection that the user don\'t own', async () => {
                // prepare
                await MFLClubTestsUtils.createClubNFT('1', '1');
                const bobAccountAddress = await getAccountAddress('BobAccount');
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_and_link_club_collection.tx',
                    signers: [bobAccountAddress],
                });

                // execute
                const err1 = await testsUtils.shallRevert({
                    name: 'mfl/clubs/withdraw_club.tx',
                    signers: [bobAccountAddress],
                    args: [bobAccountAddress, '1'],
                });
                const err2 = await testsUtils.shallRevert({
                    code: WITHDRAW_CLUB_FROM_GIVEN_ADDRESS,
                    signers: [bobAccountAddress],
                    args: [aliceAdminAccountAddress, bobAccountAddress, '1'],
                });
                const err3 = await testsUtils.shallRevert({
                    code: WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2,
                    signers: [bobAccountAddress],
                    args: [aliceAdminAccountAddress, bobAccountAddress, '1'],
                });
                await testsUtils.shallPass({
                    name: 'mfl/clubs/withdraw_club.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [bobAccountAddress, '1'],
                });
                const err4 = await testsUtils.shallRevert({
                    name: 'mfl/clubs/withdraw_club.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [aliceAdminAccountAddress, '1'],
                });
                const err5 = await testsUtils.shallRevert({
                    code: WITHDRAW_CLUB_FROM_GIVEN_ADDRESS,
                    signers: [aliceAdminAccountAddress],
                    args: [bobAccountAddress, aliceAdminAccountAddress, '1'],
                });
                const err6 = await testsUtils.shallRevert({
                    code: WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2,
                    signers: [bobAccountAddress],
                    args: [bobAccountAddress, aliceAdminAccountAddress, '1'],
                });
                const err7 = await testsUtils.shallRevert({
                    code: BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS,
                    signers: [aliceAdminAccountAddress],
                    args: [bobAccountAddress, aliceAdminAccountAddress, ['1']],
                });
                const err8 = await testsUtils.shallRevert({
                    code: BATCH_WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V2,
                    signers: [bobAccountAddress],
                    args: [bobAccountAddress, aliceAdminAccountAddress, ['1']],
                });
                const err9 = await testsUtils.shallRevert({
                    code: WITHDRAW_CLUB_FROM_GIVEN_ADDRESS_V3,
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
            test('should batch withdraw clubs NFTs from a collection and batch deposit them in another collection', async () => {
                // prepare
                await MFLClubTestsUtils.createClubNFT('1', '1');
                await MFLClubTestsUtils.createClubNFT('2', '2');
                const bobAccountAddress = await getAccountAddress('BobAccount');
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_and_link_club_collection.tx',
                    signers: [bobAccountAddress],
                });

                // execute
                const result = await testsUtils.shallPass({
                    name: 'mfl/clubs/batch_withdraw_clubs.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [bobAccountAddress, ['1', '2']],
                });

                // assert
                const expectedEvents = [
                    ...testsUtils.createExpectedWithdrawEvent('MFLClub', '1', aliceAdminAccountAddress),
                    ...testsUtils.createExpectedWithdrawEvent('MFLClub', '2', aliceAdminAccountAddress),
                    ...testsUtils.createExpectedDepositedEvent('MFLClub', '1', null),
                    ...testsUtils.createExpectedDepositedEvent('MFLClub', '2', null),
                    ...testsUtils.createExpectedWithdrawEvent('MFLClub', '1', null),
                    ...testsUtils.createExpectedDepositedEvent('MFLClub', '1', bobAccountAddress),
                    ...testsUtils.createExpectedWithdrawEvent('MFLClub', '2', null),
                    ...testsUtils.createExpectedDepositedEvent('MFLClub', '2', bobAccountAddress),
                ];
                expect(result.events).toHaveLength(expectedEvents.length);
                expect(result.events).toEqual(
                    expect.arrayContaining([
                        ...testsUtils.createExpectedWithdrawEvent('MFLClub', '1', aliceAdminAccountAddress),
                        ...testsUtils.createExpectedWithdrawEvent('MFLClub', '2', aliceAdminAccountAddress),
                        ...testsUtils.createExpectedDepositedEvent('MFLClub', '1', null),
                        ...testsUtils.createExpectedDepositedEvent('MFLClub', '2', null),
                        ...testsUtils.createExpectedWithdrawEvent('MFLClub', '1', null),
                        ...testsUtils.createExpectedDepositedEvent('MFLClub', '1', bobAccountAddress),
                        ...testsUtils.createExpectedWithdrawEvent('MFLClub', '2', null),
                        ...testsUtils.createExpectedDepositedEvent('MFLClub', '2', bobAccountAddress),
                    ]),
                );

                const aliceClubsIds = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_ids_in_collection.script',
                    args: [aliceAdminAccountAddress],
                });
                expect(aliceClubsIds).toEqual([]);

                const bobClubsIds = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_ids_in_collection.script',
                    args: [bobAccountAddress],
                });
                expect(bobClubsIds).toHaveLength(2);
                expect(bobClubsIds).toEqual(expect.arrayContaining(['1', '2']));
            });
        });

        describe('getIDs()', () => {
            test('should get the IDs in the collection', async () => {
                // prepare
                await MFLClubTestsUtils.createClubNFT('10', '1');
                await MFLClubTestsUtils.createClubNFT('42', '2');
                await MFLClubTestsUtils.createClubNFT('101', '3');

                // execute
                const ids = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_ids_in_collection.script',
                    args: [aliceAdminAccountAddress],
                });

                // assert
                expect(ids).toHaveLength(3);
                expect(ids).toEqual(expect.arrayContaining(['10', '42', '101']));
            });
        });

        describe('borrowNFT()', () => {
            test('should borrow a NFT in the collection', async () => {
                // prepare
                const clubId = '101';
                const squadId = '1';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // execute
                const clubFromCollection = await testsUtils.executeValidScript({
                    code: `
              import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
              import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
              access(all)
              fun main(address: Address, clubID: UInt64): &{NonFungibleToken.NFT}? {
                  let clubCollectionRef = getAccount(address).capabilities.borrow<&MFLClub.Collection>(
                      MFLClub.CollectionPublicPath
                  ) ?? panic("Could not borrow the collection reference")
                  let nftRef = clubCollectionRef.borrowNFT(clubID)
                  return nftRef
              }
            `,
                    args: [aliceAdminAccountAddress, clubId],
                });

                // assert
                expect(clubFromCollection).toEqual({
                    id: clubId,
                    squads: {
                        '1': {
                            id: '1',
                            clubID: clubId,
                            type: 'squadType',
                            metadata: {},
                            uuid: expect.toBeString(),
                        },
                    },
                    metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
                    uuid: expect.toBeString(),
                });
            });
        });

        describe('foundClub()', () => {
            test('should found a club when it\'s valid', async () => {
                // prepare
                const clubId = '42';
                const clubName = 'Wax FC';
                const clubDescription = 'Hello world';
                const squadId = '101';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // execute
                const result = await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription);

                // assert
                expect(result.events).toHaveLength(3);
                expect(result.events).toEqual([
                    {
                        type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubMetadataUpdated`,
                        data: {id: clubId},
                        eventIndex: expect.any(Number),
                        transactionId: expect.any(String),
                        transactionIndex: expect.any(Number),
                    },
                    {
                        type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubStatusUpdated`,
                        data: {
                            id: clubId,
                            status: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.PENDING_VALIDATION.toString()
                        },
                        eventIndex: expect.any(Number),
                        transactionId: expect.any(String),
                        transactionIndex: expect.any(Number),
                    },
                    {
                        type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubFounded`,
                        data: {
                            id: clubId,
                            from: aliceAdminAccountAddress,
                            name: clubName,
                            description: clubDescription,
                            ...MFLClubTestsUtils.FOUNDATION_LICENSE,
                            foundationLicenseImage: undefined,
                            foundationDate: expect.any(String),
                        },
                        eventIndex: expect.any(Number),
                        transactionId: expect.any(String),
                        transactionIndex: expect.any(Number),
                    },
                ]);
                const clubFromCollection = await testsUtils.executeValidScript({
                    code: `
              import NonFungibleToken from "../../../../contracts/_libs/NonFungibleToken.cdc"
              import MFLClub from "../../../../contracts/clubs/MFLClub.cdc"
  
              access(all)
              fun main(address: Address, clubID: UInt64): &{NonFungibleToken.NFT}? {
                  let clubCollectionRef = getAccount(address).capabilities.borrow<&MFLClub.Collection>(
                      MFLClub.CollectionPublicPath
                  ) ?? panic("Could not borrow the collection reference")
                  let nftRef = clubCollectionRef.borrowNFT(clubID)
                  return nftRef
              }
            `,
                    args: [aliceAdminAccountAddress, clubId],
                });
                expect(clubFromCollection).toEqual({
                    uuid: expect.any(String),
                    id: clubId,
                    squads: {
                        [`${squadId}`]: {
                            uuid: expect.any(String),
                            id: squadId,
                            clubID: clubId,
                            type: 'squadType',
                            metadata: {}
                        },
                    },
                    metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
                });
                const clubData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_club_data.script',
                    args: [clubId],
                });
                expect(clubData).toEqual({
                    id: clubId,
                    status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.PENDING_VALIDATION.toString()},
                    squadsIDs: [squadId],
                    metadata: {
                        ...MFLClubTestsUtils.FOUNDATION_LICENSE,
                        foundationDate: expect.any(String),
                        name: clubName,
                        description: clubDescription,
                    },
                });
            });

            test('should throw an error when trying to found a club the wallet doesn\'t own', async () => {
                // prepare
                const clubId = '42';
                const clubName = 'Yax FC';
                const clubDescription = 'Hello world';
                const squadId = '101';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);
                const aliceAdminAccountAddress = await getAccountAddress('AliceAdminAccount');
                const bobAccountAddress = await getAccountAddress('BobAccount');
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_and_link_club_collection.tx',
                    signers: [bobAccountAddress],
                });

                // execute
                const err1 = await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription, false, 'BobAccount');
                // const er = await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription, true, 'AliceAdminAccount');
                const err2 = await testsUtils.shallRevert({
                    code: FOUND_CLUB_MALICIOUS,
                    args: [aliceAdminAccountAddress, clubId, clubName, clubDescription],
                    signers: [bobAccountAddress],
                });

                // assert
                expect(err1).toContain('Club not found');
                expect(err2).toContain('function requires `ClubAction` authorization, but reference is unauthorized');
            });

            test('should throw an error when the club nft does not exist', async () => {
                // prepare

                // execute
                const error = await MFLClubTestsUtils.foundClub('404', 'name', 'description', false);

                // assert
                expect(error).toContain('Club not found');
            });

            test('should throw an error when the club status is founded', async () => {
                // prepare
                const clubId = '42';
                const clubName = 'Wax FC';
                const clubDescription = 'Hello world';
                const squadId = '101';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);
                await testsUtils.shallPass({
                    name: 'mfl/clubs/update_club_status.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [clubId, '2'],
                });

                // execute
                const error = await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription, false);

                // assert
                expect(error).toContain('Club already founded');
            });

            test('should throw an error when the club status is pending validation', async () => {
                // prepare
                const clubId = '42';
                const clubName = 'Wax FC';
                const clubDescription = 'Hello world';
                const squadId = '101';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);
                await testsUtils.shallPass({
                    name: 'mfl/clubs/update_club_status.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [clubId, 1],
                });

                // execute
                const error = await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription, false);

                // assert
                expect(error).toContain('Club already founded');
            });
        });

        describe('requestClubInfoUpdate()', () => {
            test('should emit an event when it\'s valid', async () => {
                // prepare
                const clubId = '1';
                const clubInfo = {
                    name: 'The MFL Club',
                    description: 'The club number 1',
                };
                await MFLClubTestsUtils.createClubNFT(clubId, 1);
                await testsUtils.shallPass({
                    name: 'mfl/clubs/update_club_status.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [clubId, '2'],
                });

                // execute
                const result = await testsUtils.shallPass({
                    name: 'mfl/clubs/request_club_info_update.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [clubId, clubInfo.name, clubInfo.description],
                });

                // assert
                expect(result.events).toHaveLength(1);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubInfoUpdateRequested`,
                    data: {id: clubId, info: clubInfo},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
            });

            test('should throw an error when the wallet doesn\'t own the club', async () => {
                // prepare
                const bobAccountAddress = await getAccountAddress('BobAccount');
                const clubId = '1';
                const clubInfo = {
                    name: 'The MFL Club',
                    description: 'The club number 1',
                };
                await MFLClubTestsUtils.createClubNFT(clubId, 1);
                await testsUtils.shallPass({
                    name: 'mfl/clubs/update_club_status.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [clubId, '2'],
                });

                // execute
                const err = await testsUtils.shallRevert({
                    code: REQUEST_CLUB_INFO_UPDATE_MALICIOUS,
                    signers: [bobAccountAddress],
                    args: [aliceAdminAccountAddress, clubId, clubInfo.name, clubInfo.description],
                });

                // assert
                expect(err).toContain("function requires `ClubAction` authorization, but reference is unauthorized");
            });

            test('should throw an error when club nft does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/request_club_info_update.tx',
                    signers: [aliceAdminAccountAddress],
                    args: ['108', 'name', 'description'],
                });

                // assert
                expect(error).toContain('Club not found');
            });

            test('should throw an error when club is not founded', async () => {
                // prepare
                const clubId = '1';
                const clubInfo = {
                    name: 'The MFL Club',
                    description: 'The club number 1',
                };
                await MFLClubTestsUtils.createClubNFT(clubId, '1');

                // execute
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/request_club_info_update.tx',
                    signers: [aliceAdminAccountAddress],
                    args: [clubId, clubInfo.name, clubInfo.description],
                });

                // assert
                expect(error).toContain('Club not founded');
            });
        });

        describe('destroy', () => {
            test('should destroy a collection', async () => {
                // prepare
                await MFLClubTestsUtils.createClubNFT(1, 1);
                await MFLClubTestsUtils.createClubNFT(2, 2);

                // execute
                const result = await testsUtils.shallPass({
                    code: `
            import MFLClub from "../../../contracts/players/MFLClub.cdc"
            
            transaction() {
            
                prepare(acct: auth(LoadValue) &Account) {
                    let collection <- acct.storage.load<@MFLClub.Collection>(from: MFLClub.CollectionStoragePath)!
                    destroy collection
                }
            }
            `,
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(2);
                expect(result.events).toEqual(
                    expect.arrayContaining([
                        {
                            type: 'A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed',
                            data: {id: '1', uuid: expect.toBeString()},
                            eventIndex: expect.any(Number),
                            transactionId: expect.any(String),
                            transactionIndex: expect.any(Number),
                        },
                        {
                            type: 'A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed',
                            data: {id: '2', uuid: expect.toBeString()},
                            eventIndex: expect.any(Number),
                            transactionId: expect.any(String),
                            transactionIndex: expect.any(Number),
                        },
                    ]),
                );
            });
        });

        describe('createEmptyCollection()', () => {
            test('should create an empty collection', async () => {
                // prepare
                const bobAccountAddress = await getAccountAddress('BobAccount');

                // execute
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_and_link_club_collection.tx',
                    signers: [bobAccountAddress],
                });

                // assert
                await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_ids_in_collection.script',
                    args: [bobAccountAddress],
                });
            });
        });

        describe('Club NFT', () => {
            describe('getViews()', () => {
                test('should get views types', async () => {
                    // prepare
                    await MFLClubTestsUtils.createClubNFT('1', '1');

                    // execute
                    const viewsTypes = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_club_views_from_collection.script',
                        args: [aliceAdminAccountAddress, '1'],
                    });

                    // assert
                    expect(viewsTypes).toHaveLength(7);
                    expect(viewsTypes.map((viewType) => viewType.typeID)).toEqual(
                        expect.arrayContaining([
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Display`,
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Royalties`,
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionDisplay`,
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.NFTCollectionData`,
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.ExternalURL`,
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Traits`,
                            `A.${testsUtils.sansPrefix(addressMap.MetadataViews)}.MetadataViews.Serial`,
                        ]),
                    );
                });
            });

            describe('resolveView()', () => {
                test('should resolve Display view for a specific club', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '1');

                    // execute
                    const clubDisplayView = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_club_display_view_from_collection.script',
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubDisplayView).toEqual({
                        name: `Club License #${clubId}`,
                        description: `MFL Club License #${clubId}`,
                        thumbnail: `https://d13e14gtps4iwl.cloudfront.net/clubs/${clubId}/licenses/foundation.png`,
                        owner: aliceAdminAccountAddress,
                        type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
                    });
                });

                test('should resolve Display view for a founded club', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '1');
                    await MFLClubTestsUtils.foundClub(clubId, 'Some Club 1000', 'Some Description 1000');
                    await testsUtils.shallPass({
                        code: UPDATE_CLUB_METADATA,
                        args: [clubId, 'Some Club 2000', 'Some Description 2000', "v1", "2", aliceAdminAccountAddress],
                        signers: [aliceAdminAccountAddress],
                    });

                    // execute
                    const clubDisplayView = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_club_display_view_from_collection.script',
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubDisplayView).toEqual({
                        name: "Some Club 2000",
                        description: "Before purchasing this MFL Club, make sure to check the club's in-game profile for the latest information: https://app.playmfl.com/clubs/1000\n\n---\n\nSome Description 2000",
                        thumbnail: `https://d13e14gtps4iwl.cloudfront.net/u/clubs/${clubId}/logo.png?v=2`,
                        owner: aliceAdminAccountAddress,
                        type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
                    });
                });

                test('should resolve Royalties view for a specific club', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '1');

                    // execute
                    const clubRoyaltiesView = await testsUtils.executeValidScript({
                        code: GET_CLUB_ROYALTIES_VIEW,
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubRoyaltiesView).toEqual({
                        cutInfos: [{
                            receiver: {
                                id: '0',
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

                test('should resolve Traits view for a specific club', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '2', true, 'AliceAdminAccount', 1);

                    // execute
                    const clubTraitsView = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_club_traits_view_from_collection.script',
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubTraitsView).toEqual({
                        traits: [
                            {
                                displayType: 'String',
                                name: 'city',
                                rarity: null,
                                value: 'Paris',
                            },
                            {
                                displayType: 'String',
                                name: 'country',
                                rarity: null,
                                value: 'France',
                            },
                            {
                                displayType: 'Number',
                                name: 'division',
                                rarity: null,
                                value: '1',
                            },
                        ],
                    });
                });

                test('should resolve Traits view for a specific founded club', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '2', true, 'AliceAdminAccount', 1);
                    await MFLClubTestsUtils.foundClub(clubId, 'Some Club', 'Some Description');

                    // execute
                    const clubTraitsView = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_club_traits_view_from_collection.script',
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubTraitsView).toEqual({
                        traits: [
                            {
                                displayType: 'String',
                                name: 'city',
                                rarity: null,
                                value: 'Paris',
                            },
                            {
                                displayType: 'String',
                                name: 'country',
                                rarity: null,
                                value: 'France',
                            },
                            {
                                displayType: 'Number',
                                name: 'division',
                                rarity: null,
                                value: '1',
                            },
                        ],
                    });
                });

                test('should resolve Traits view for a specific club without a division for global league', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '1');

                    // execute
                    const clubTraitsView = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_club_traits_view_from_collection.script',
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubTraitsView).toEqual({
                        traits: [
                            {
                                displayType: 'String',
                                name: 'city',
                                rarity: null,
                                value: 'Paris',
                            },
                            {
                                displayType: 'String',
                                name: 'country',
                                rarity: null,
                                value: 'France',
                            },
                        ],
                    });
                });

                test('should resolve Serial view for a specific club', async () => {
                    // prepare
                    const clubId = '1000';
                    await MFLClubTestsUtils.createClubNFT(clubId, '1');

                    // execute
                    const clubSerialView = await testsUtils.executeValidScript({
                        code: GET_CLUB_SERIAL_VIEW,
                        args: [aliceAdminAccountAddress, clubId],
                    });

                    // assert
                    expect(clubSerialView).toEqual({number: clubId});
                });

                test('should resolve Display view for all clubs', async () => {
                    // prepare
                    const clubId1 = '450';
                    const clubId2 = '578';
                    await MFLClubTestsUtils.createClubNFT(clubId1, '1');
                    await MFLClubTestsUtils.createClubNFT(clubId2, '2');

                    // execute
                    const clubsDisplayView = await testsUtils.executeValidScript({
                        name: 'mfl/clubs/get_clubs_display_view_from_collection.script',
                        args: [aliceAdminAccountAddress, [clubId1, clubId2]],
                    });

                    // assert
                    expect(clubsDisplayView).toEqual(
                        expect.arrayContaining([
                            {
                                name: `Club License #${clubId1}`,
                                description: `MFL Club License #${clubId1}`,
                                thumbnail: `https://d13e14gtps4iwl.cloudfront.net/clubs/${clubId1}/licenses/foundation.png`,
                                owner: aliceAdminAccountAddress,
                                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
                            },
                            {
                                name: `Club License #${clubId2}`,
                                description: `MFL Club License #${clubId2}`,
                                thumbnail: `https://d13e14gtps4iwl.cloudfront.net/clubs/${clubId2}/licenses/foundation.png`,
                                owner: aliceAdminAccountAddress,
                                type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
                            },
                        ]),
                    );
                });
            });

            describe('destroy()', () => {
                test('should destroy the NFT', async () => {
                    // prepare
                    const clubId = '450';
                    const squadId = '1';
                    await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                    // execute
                    const signers = [aliceAdminAccountAddress];
                    const args = [clubId];
                    const result = await testsUtils.shallPass({name: 'mfl/clubs/destroy_club.tx', args, signers});

                    // assert
                    expect(result.events).toHaveLength(3);
                    expect(result.events).toPartiallyContain({
                        type: `A.f8d6e0586b0a20c7.NonFungibleToken.NFT.ResourceDestroyed`,
                        data: {id: clubId, uuid: expect.toBeString()},
                    });
                    const error = await testsUtils.executeFailingScript({
                        name: 'mfl/clubs/get_club_display_view_from_collection.script',
                        args: [aliceAdminAccountAddress, clubId],
                    });
                    expect(error.message).toContain('unexpectedly found nil while forcing an Optional value');
                });
            });
        });
    });

    describe('getClubData()', () => {
        test('should get club data for a not founded club', async () => {
            // prepare
            const clubId = '42';
            const squadId = '101';
            await MFLClubTestsUtils.createClubNFT(clubId, squadId);

            // execute
            const clubData = await testsUtils.executeValidScript({
                name: 'mfl/clubs/get_club_data.script',
                args: [clubId],
            });

            // assert
            expect(clubData).toEqual({
                id: clubId,
                metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
                status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.NOT_FOUNDED.toString()},
                squadsIDs: [squadId],
            });
        });

        test('should get club data for a founded club', async () => {
            // prepare
            const clubId = '42';
            const clubName = 'Wax FC';
            const clubDescription = 'Hello world';
            const squadId = '101';
            await MFLClubTestsUtils.createClubNFT(clubId, squadId);
            await MFLClubTestsUtils.foundClub(clubId, clubName, clubDescription);

            // execute
            const clubData = await testsUtils.executeValidScript({
                name: 'mfl/clubs/get_club_data.script',
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
                status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.PENDING_VALIDATION.toString()},
                squadsIDs: [squadId],
            });
        });

        test('should return nil when getting club data for an unknown club', async () => {
            // prepare

            // execute
            const clubData = await testsUtils.executeValidScript({
                name: 'mfl/clubs/get_club_data.script',
                args: ['4'],
            });

            // assert
            expect(clubData).toBeNull();
        });

        test('should throw an error when updating club metadata', async () => {
            // prepare
            const clubId = '1';
            await MFLClubTestsUtils.createClubNFT(clubId, '1');

            // execute
            const error = await testsUtils.shallRevert({
                code: ERROR_UPDATE_CLUB_METADATA,
                args: [clubId],
            });

            // assert
            expect(error).toContain('cannot access `metadata`: field requires `self` authorization');
        });
    });

    describe('getSquadData()', () => {
        test('should get squad data for a not founded club', async () => {
            // prepare
            const clubId = '42';
            const squadId = '101';
            await MFLClubTestsUtils.createClubNFT(clubId, squadId);

            // execute
            const squadData = await testsUtils.executeValidScript({
                name: 'mfl/clubs/squads/get_squad_data.script',
                args: [squadId],
            });

            // assert
            expect(squadData).toEqual({
                id: squadId,
                clubID: clubId,
                type: 'squadType',
                status: {rawValue: MFLClubTestsUtils.SQUAD_STATUS_RAW_VALUES.ACTIVE.toString()},
                metadata: {},
                competitionsMemberships: {'42': {division: '1'}},
            });
        });

        test('should return nil when getting squad data for an unknown squad', async () => {
            // prepare

            // execute
            const squadData = await testsUtils.executeValidScript({
                name: 'mfl/clubs/squads/get_squad_data.script',
                args: ['4'],
            });

            // assert
            expect(squadData).toBeNull();
        });

        test('should throw an error when updating squad metadata', async () => {
            // prepare
            const squadId = '1';
            await MFLClubTestsUtils.createClubNFT('1', squadId);

            // execute
            const error = await testsUtils.shallRevert({
                code: ERROR_UPDATE_SQUAD_METADATA,
                args: [squadId],
            });

            // assert
            expect(error).toContain('cannot access `metadata`: field requires `self` authorization');
        });
    });

    describe('ClubAdmin', () => {
        describe('mintClub()', () => {
            test('should mint a club', async () => {
                // prepare
                const clubId = '1';
                const squadId = '1';

                // execute
                const result = await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // assert
                expect(result.events).toHaveLength(5);
                expect(result.events).toEqual(
                    expect.arrayContaining([
                        {
                            type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadCompetitionMembershipAdded`,
                            data: {competitionID: '42', id: squadId},
                            eventIndex: expect.any(Number),
                            transactionId: expect.any(String),
                            transactionIndex: expect.any(Number),
                        },
                        {
                            type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadMinted`,
                            data: {id: squadId},
                            eventIndex: expect.any(Number),
                            transactionId: expect.any(String),
                            transactionIndex: expect.any(Number),
                        },
                        {
                            type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubMinted`,
                            data: {id: clubId},
                            eventIndex: expect.any(Number),
                            transactionId: expect.any(String),
                            transactionIndex: expect.any(Number),
                        },
                        ...testsUtils.createExpectedDepositedEvent('MFLClub', clubId, aliceAdminAccountAddress),
                    ]),
                );
                const clubData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_club_data.script',
                    args: [clubId],
                });
                const squadData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/squads/get_squad_data.script',
                    args: [squadId],
                });
                const totalSupply = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_clubs_total_supply.script',
                });
                const squadsTotalSupply = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/squads/get_squads_total_supply.script',
                });
                expect(clubData).toEqual({
                    id: clubId,
                    metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
                    status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.NOT_FOUNDED.toString()},
                    squadsIDs: [squadId],
                });
                expect(squadData).toEqual({
                    id: squadId,
                    clubID: clubId,
                    type: 'squadType',
                    status: {rawValue: MFLClubTestsUtils.SQUAD_STATUS_RAW_VALUES.ACTIVE.toString()},
                    metadata: {},
                    competitionsMemberships: {'42': {division: '1'}},
                });
                expect(totalSupply).toBe('1');
                expect(squadsTotalSupply).toBe('1');
            });

            test('should panic when minting a club id already minted', async () => {
                // prepare
                const clubId = '1';

                // execute
                await MFLClubTestsUtils.createClubNFT(clubId, '1');
                const error = await MFLClubTestsUtils.createClubNFT(clubId, '2', false);

                // assert
                expect(error).toContain('Club already exists');
            });
        });

        describe('updateClubStatus()', () => {
            test('should update club status', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // execute
                const result = await testsUtils.shallPass({
                    name: 'mfl/clubs/update_club_status.tx',
                    args: [clubId, MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.FOUNDED.toString()],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(1);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubStatusUpdated`,
                    data: {id: clubId, status: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.FOUNDED.toString()},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const clubData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_club_data.script',
                    args: [clubId],
                });
                expect(clubData).toEqual({
                    id: clubId,
                    status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.FOUNDED.toString()},
                    squadsIDs: [squadId],
                    metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
                });
            });

            test('should throw an error when club does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/update_club_status.tx',
                    args: ['208', MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.FOUNDED],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Club data not found');
            });
        });

        describe('updateClubMetadata()', () => {
            test('should update club metadata', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                const updatedClubName = 'New Club Name';
                const updatedClubDescription = 'New Club Description';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // execute
                const result = await testsUtils.shallPass({
                    code: UPDATE_CLUB_METADATA,
                    args: [clubId, updatedClubName, updatedClubDescription, "v1", "2", aliceAdminAccountAddress],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(2);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubMetadataUpdated`,
                    data: {id: clubId},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                expect(result.events[1]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.NonFungibleToken)}.NonFungibleToken.Updated`,
                    data: {
                        id: clubId,
                        owner: aliceAdminAccountAddress,
                        type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.NFT`,
                        uuid: expect.any(String)
                    },
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const clubData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_club_data.script',
                    args: [clubId],
                });
                expect(clubData).toEqual({
                    id: clubId,
                    status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.NOT_FOUNDED.toString()},
                    squadsIDs: [squadId],
                    metadata: {
                        name: updatedClubName,
                        description: updatedClubDescription,
                        logoVersion: "v1",
                        division: "2"
                    },
                });
            });

            test('should throw an error when club does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    code: UPDATE_CLUB_METADATA,
                    args: ['208', 'New name', 'New description', 'v1', '2', aliceAdminAccountAddress],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Club data not found');
            });
        });

        describe('updateClubSquadsIDs()', () => {
            test('should update club squads ids', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // execute
                const result = await testsUtils.shallPass({
                    name: 'mfl/clubs/update_club_squads_ids.tx',
                    args: [clubId, [squadId, '42']],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(1);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.ClubSquadsIDsUpdated`,
                    data: {id: clubId, squadsIDs: [squadId, '42']},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const clubData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/get_club_data.script',
                    args: [clubId],
                });
                expect(clubData).toEqual({
                    id: clubId,
                    status: {rawValue: MFLClubTestsUtils.CLUB_STATUS_RAW_VALUES.NOT_FOUNDED.toString()},
                    squadsIDs: [squadId, '42'],
                    metadata: MFLClubTestsUtils.FOUNDATION_LICENSE,
                });
            });

            test('should throw an error when club does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/update_club_squads_ids.tx',
                    args: ['208', ['42']],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Club data not found');
            });
        });

        describe('createClubAdmin()', () => {
            test('should create a club admin', async () => {
                // prepare
                const bobAccountAddress = await getAccountAddress('BobAccount');
                const jackAccountAddress = await getAccountAddress('JackAccount');

                // execute
                const signers = [aliceAdminAccountAddress, bobAccountAddress];
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_club_admin.tx',
                    signers,
                });

                // assert
                // bob must now be able to create another club admin
                await testsUtils.shallPass({
                    name: 'mfl/clubs/create_club_admin.tx',
                    signers: [bobAccountAddress, jackAccountAddress],
                });
            });

            test('should panic when trying to create a club admin with a non admin account', async () => {
                // prepare
                const bobAccountAddress = await getAccountAddress('BobAccount');
                const jackAccountAddress = await getAccountAddress('JackAccount');

                // execute
                const signers = [bobAccountAddress, jackAccountAddress];
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/create_club_admin.tx',
                    signers,
                });

                // assert
                expect(error).toContain('Could not borrow club admin ref');
            });
        });
    });

    describe('SquadAdmin', () => {
        describe('updateSquadMetadata()', () => {
            test('should update squad metadata', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                const updatedSquadName = 'My squad';
                const updatedSquadDescription = 'My squad description';
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
                    data: {id: squadId},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const squadData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/squads/get_squad_data.script',
                    args: [squadId],
                });
                expect(squadData).toEqual({
                    id: squadId,
                    clubID: clubId,
                    type: 'squadType',
                    status: {rawValue: MFLClubTestsUtils.SQUAD_STATUS_RAW_VALUES.ACTIVE.toString()},
                    metadata: {
                        name: updatedSquadName,
                        description: updatedSquadDescription,
                    },
                    competitionsMemberships: {'42': {division: '1'}},
                });
            });

            test('should throw an error when squad does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    code: UPDATE_SQUAD_METADATA,
                    args: ['208', 'New name', 'New description'],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Squad data not found');
            });
        });

        describe('addSquadCompetitionMembership()', () => {
            test('should add competitionMembership', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                const competitionId = '567';
                const competitionMembershipDataName = 'The competition';
                const competitionMembershipDataReward = '10000';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);

                // execute
                const result = await testsUtils.shallPass({
                    code: ADD_SQUAD_COMPETITION_MEMBERSHIP,
                    args: [squadId, competitionId, competitionMembershipDataName, competitionMembershipDataReward],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(1);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadCompetitionMembershipAdded`,
                    data: {id: squadId, competitionID: competitionId},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const squadData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/squads/get_squad_data.script',
                    args: [squadId],
                });
                expect(squadData).toEqual({
                    id: squadId,
                    clubID: clubId,
                    type: 'squadType',
                    status: {rawValue: MFLClubTestsUtils.SQUAD_STATUS_RAW_VALUES.ACTIVE.toString()},
                    metadata: {},
                    competitionsMemberships: {
                        '42': {division: '1'},
                        [`${competitionId}`]: {
                            name: competitionMembershipDataName,
                            reward: competitionMembershipDataReward
                        },
                    },
                });
            });

            test('should throw an error when squad does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    code: ADD_SQUAD_COMPETITION_MEMBERSHIP,
                    args: ['208', '42', 'The competition', '900'],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Squad data not found');
            });
        });

        describe('updateSquadCompetitionMembership()', () => {
            test('should update competitionMembership', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                const competitionId = '567';
                const competitionMembershipDataName = 'The competition';
                const competitionMembershipDataReward = '10000';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);
                await testsUtils.shallPass({
                    code: ADD_SQUAD_COMPETITION_MEMBERSHIP,
                    args: [squadId, competitionId, competitionMembershipDataName, competitionMembershipDataReward],
                    signers: [aliceAdminAccountAddress],
                });

                // execute
                const result = await testsUtils.shallPass({
                    code: UPDATE_SQUAD_COMPETITION_MEMBERSHIP,
                    args: [squadId, competitionId, 'updated competition name', '400'],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(1);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadCompetitionMembershipUpdated`,
                    data: {id: squadId, competitionID: competitionId},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const squadData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/squads/get_squad_data.script',
                    args: [squadId],
                });
                expect(squadData).toEqual({
                    id: squadId,
                    clubID: clubId,
                    type: 'squadType',
                    status: {rawValue: MFLClubTestsUtils.SQUAD_STATUS_RAW_VALUES.ACTIVE.toString()},
                    metadata: {},
                    competitionsMemberships: {
                        '42': {division: '1'},
                        [`${competitionId}`]: {name: 'updated competition name', reward: '400'},
                    },
                });
            });

            test('should throw an error when squad does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    code: UPDATE_SQUAD_COMPETITION_MEMBERSHIP,
                    args: ['208', '42', 'The competition', '900'],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Squad data not found');
            });

            test('should throw an error when squad does not have the competition membership', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                const competitionId = '567';
                const competitionMembershipDataName = 'The competition';
                const competitionMembershipDataReward = '10000';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);
                await testsUtils.shallPass({
                    code: ADD_SQUAD_COMPETITION_MEMBERSHIP,
                    args: [squadId, competitionId, competitionMembershipDataName, competitionMembershipDataReward],
                    signers: [aliceAdminAccountAddress],
                });

                // execute
                const error = await testsUtils.shallRevert({
                    code: UPDATE_SQUAD_COMPETITION_MEMBERSHIP,
                    args: ['10', '43', 'The competition', '900'],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Competition membership not found');
            });
        });

        describe('removeSquadCompetitionMembership()', () => {
            test('should remove competitionMembership', async () => {
                // prepare
                const clubId = '1';
                const squadId = '10';
                const competitionId = '10089';
                await MFLClubTestsUtils.createClubNFT(clubId, squadId);
                await testsUtils.shallPass({
                    code: ADD_SQUAD_COMPETITION_MEMBERSHIP,
                    args: [squadId, competitionId, 'The competition', '900'],
                    signers: [aliceAdminAccountAddress],
                });

                // execute
                const result = await testsUtils.shallPass({
                    name: 'mfl/clubs/squads/remove_squad_competition_membership.tx',
                    args: [squadId, competitionId],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(result.events).toHaveLength(1);
                expect(result.events[0]).toEqual({
                    type: `A.${testsUtils.sansPrefix(addressMap.MFLClub)}.MFLClub.SquadCompetitionMembershipRemoved`,
                    data: {id: squadId, competitionID: competitionId},
                    eventIndex: expect.any(Number),
                    transactionId: expect.any(String),
                    transactionIndex: expect.any(Number),
                });
                const squadData = await testsUtils.executeValidScript({
                    name: 'mfl/clubs/squads/get_squad_data.script',
                    args: [squadId],
                });
                expect(squadData).toEqual({
                    id: squadId,
                    clubID: clubId,
                    type: 'squadType',
                    status: {rawValue: MFLClubTestsUtils.SQUAD_STATUS_RAW_VALUES.ACTIVE.toString()},
                    metadata: {},
                    competitionsMemberships: {'42': {division: '1'}},
                });
            });

            test('should throw an error when squad does not exist', async () => {
                // prepare

                // execute
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/squads/remove_squad_competition_membership.tx',
                    args: ['208', '31'],
                    signers: [aliceAdminAccountAddress],
                });

                // assert
                expect(error).toContain('Squad data not found');
            });
        });

        describe('createSquadAdmin()', () => {
            test('should create a squad admin', async () => {
                // prepare
                const bobAccountAddress = await getAccountAddress('BobAccount');
                const jackAccountAddress = await getAccountAddress('JackAccount');

                // execute
                const signers = [aliceAdminAccountAddress, bobAccountAddress];
                await testsUtils.shallPass({
                    name: 'mfl/clubs/squads/create_squad_admin.tx',
                    signers,
                });

                // assert
                // bob must now be able to create another squad admin
                await testsUtils.shallPass({
                    name: 'mfl/clubs/squads/create_squad_admin.tx',
                    signers: [bobAccountAddress, jackAccountAddress],
                });
            });

            test('should panic when trying to create a squad admin with a non admin account', async () => {
                // prepare
                const bobAccountAddress = await getAccountAddress('BobAccount');
                const jackAccountAddress = await getAccountAddress('JackAccount');

                // execute
                const signers = [bobAccountAddress, jackAccountAddress];
                const error = await testsUtils.shallRevert({
                    name: 'mfl/clubs/squads/create_squad_admin.tx',
                    signers,
                });

                // assert
                expect(error).toContain('Could not borrow squad admin ref');
            });
        });
    });
});

import {emulator, getAccountAddress} from '@onflow/flow-js-testing';
import {testsUtils} from '../_utils/tests.utils';
import * as matchers from 'jest-extended';
import {MFLPackTestsUtils} from '../packs/_utils/MFLPackTests.utils';

expect.extend(matchers);
jest.setTimeout(40000);

describe('MFLCommon', () => {

  beforeEach(async () => {
    await testsUtils.initEmulator();
    await MFLPackTestsUtils.deployMFLPackContract('AliceAdminAccount');
  });

  afterEach(async () => {
    await emulator.stop();
  });

  describe('create and link collections', () => {
    test('should create and link collections', async () => {
      // prepare
      const bobAccountAddress = await getAccountAddress('BobAccount');

      // execute
      const result1 = await testsUtils.shallPass({
        name: 'mfl/common/create_and_link_collections.tx',
        signers: [bobAccountAddress],
      });
      const result2 = await testsUtils.shallPass({
        name: 'mfl/common/create_and_link_collections.tx',
        signers: [bobAccountAddress],
      });

      // assert
      await testsUtils.executeValidScript({
        name: 'mfl/packs/get_ids_in_collection.script',
        args: [bobAccountAddress],
      });
      await testsUtils.executeValidScript({
        name: 'mfl/players/get_ids_in_collection.script',
        args: [bobAccountAddress],
      });
      await testsUtils.executeValidScript({
        name: 'mfl/clubs/get_ids_in_collection.script',
        args: [bobAccountAddress],
      });
      expect(result1.events).toHaveLength(6);
      expect(result2.events).toHaveLength(0);
    });
  });
});

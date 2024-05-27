import {getAccountAddress} from '@onflow/flow-js-testing';
import {testsUtils} from '../../_utils/tests.utils';

export const MFLPackTemplateTestsUtils = {

  async deployMFLPackTemplateContract(toAccountName) {
    const to = await getAccountAddress(toAccountName);
    const addressMap = {};
    await testsUtils.deployContract('MFLAdmin', to, 'core/MFLAdmin', addressMap);
    await testsUtils.deployContract('MFLPackTemplate', to, 'packs/MFLPackTemplate', addressMap);
    return addressMap;
  },

  async createPackTemplateAdmin(rootAdminAccountName, receiverAccountName) {
    const rootAdminAcctAddress = await getAccountAddress(rootAdminAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName);

    await testsUtils.shallPass({name: 'mfl/core/create_admin_proxy.tx', signers: [receiverAcctAddress]});
    await testsUtils.shallPass({
      name: 'mfl/packs/give_pack_template_admin_claim.tx',
      args: [receiverAcctAddress],
      signers: [rootAdminAcctAddress],
    });
  },
};

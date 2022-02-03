import {getAccountAddress, getServiceAddress} from 'flow-js-testing';
import {testsUtils} from '../../_utils/tests.utils';
import {MFLDropTestsUtils} from '../../drops/_utils/MFLDropTests.utils'
import {MFLPackTemplateTestsUtils} from '../../packs/_utils/MFLPackTemplateTests.utils'

export const MFLPackTestsUtils = {

  async deployMFLPackContract(toAccountName) {
    const serviceAddress = await getServiceAddress();
    const to = await getAccountAddress(toAccountName);

    const addressMap = {};
    await testsUtils.deployContract('NonFungibleToken', serviceAddress, '_libs/NonFungibleToken', addressMap);
    await testsUtils.deployContract('MetadataViews', serviceAddress, '_libs/MetadataViews', addressMap);
    await testsUtils.deployContract('FUSD', to, '_libs/FUSD', addressMap);
    await testsUtils.deployContract('MFLAdmin', to, 'core/MFLAdmin', addressMap);
    await testsUtils.deployContract('MFLPackTemplate', to, 'packs/MFLPackTemplate', addressMap);
    await testsUtils.deployContract('MFLViews', to, 'views/MFLViews', addressMap);
    await testsUtils.deployContract('MFLPack', to, 'packs/MFLPack', addressMap);
    await testsUtils.deployContract('MFLDrop', to, 'drops/MFLDrop', addressMap);
    return addressMap;
  },

  async initPackTemplateAndDrop(rootAdminAccountName, receiverAccountName, argsPackTemplate, argsDrop) {
    await MFLDropTestsUtils.createDropAdmin(rootAdminAccountName, receiverAccountName);
    await MFLPackTemplateTestsUtils.createPackTemplateAdmin(rootAdminAccountName, receiverAccountName);
    const receiverAcctAddress = await getAccountAddress(receiverAccountName)
    await testsUtils.shallPass({name: 'mfl/packs/create_pack_template.tx', args: argsPackTemplate, signers: [receiverAcctAddress]});
    await testsUtils.shallPass({name: 'mfl/drops/create_drop.tx', args: argsDrop, signers: [receiverAcctAddress]});
    await testsUtils.shallPass({name: 'mfl/drops/set_owner_vault.tx', args: [], signers: [receiverAcctAddress]});
    await testsUtils.shallPass({name: 'mfl/drops/set_status_opened_all.tx', args: [argsDrop[2]], signers: [receiverAcctAddress]});
  },

  async setupAndTopupFusdAccount(senderAcctAddress, receiverAcctAddress, amount) {
    await testsUtils.shallPass({name: 'fusd/setup_account.tx', args: [], signers: [receiverAcctAddress] });
    await testsUtils.shallPass({name: 'fusd/send_fusd.tx', args: [receiverAcctAddress, amount], signers: [senderAcctAddress]});
  },

  async purchase(acctAddress, args) {
    await testsUtils.shallPass({name: 'mfl/drops/purchase.tx', args, signers: [acctAddress]});
  },
}
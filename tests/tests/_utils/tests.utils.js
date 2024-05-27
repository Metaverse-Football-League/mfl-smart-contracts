import {deployContract, emulator, executeScript, getContractCode, init, sendTransaction} from '@onflow/flow-js-testing';
import path from 'path';

export const testsUtils = {
  async initEmulator() {
    const basePath = path.resolve(__dirname, '../../../');
    await init(basePath);
    await emulator.start({logging: true});
  },

  async deployContract(name, to, path, addressMap) {
    const code = await getContractCode({name: path, addressMap});
    const [result, error] = await deployContract({
      code,
      name,
      to,
      addressMap,
      update: true,
    });

    if (error) {
      console.error(`Error deploying ${name} contract: `, error);
      throw error;
    }

    addressMap[name] = to;
    return result;
  },

  async shallRevert(props) {
    const [a, error] = await sendTransaction(props);
    if (!error) {
      throw `Should have thrown an error for ${props.name}`;
    }
    return error;
  },

  async shallPass(props) {
    const [result, error] = await sendTransaction(props);
    if (error) {
      console.error(`Error sending tx ${props.name}:`, error);
      throw error;
    }
    expect(result.status).toBe(4);
    return result;
  },

  async executeValidScript(props) {
    const [result, error] = await executeScript(props);
    if (error) {
      console.error(`Error executing script ${props.name}:`, error);
      throw error;
    }
    return result;
  },

  async executeFailingScript(props) {
    const [result, error] = await executeScript(props);
    if (!error) {
      throw `Should have thrown an error for ${props.name}`;
    }
    return error;
  },

  sansPrefix(address) {
    if (address == null) return null;
    return address.replace(/^0x/, '');
  },

  withPrefix(address) {
    if (address == null) return null;
    return '0x' + testsUtils.sansPrefix(address);
  },
};

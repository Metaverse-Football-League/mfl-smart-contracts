import {deployContract, emulator, executeScript, getContractCode, init, sendTransaction} from '@onflow/flow-js-testing';
import path from 'path';

export const testsUtils = {
  async initEmulator() {
    const basePath = path.resolve(__dirname, '../../../');
    await init(basePath);
    // await emulator.start({logging: true, grpcPort: 3569, restPort: 8888, adminPort: 8080, debuggerPort: 2345});
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
    console.log("iii", a);
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

  createExpectedWithdrawEvent(contract, id, from) {
    if (!id || from === undefined) throw new Error('id and from are required');
    return {
      type: 'A.f8d6e0586b0a20c7.NonFungibleToken.Withdrawn',
      transactionId: expect.toBeString(),
      transactionIndex: expect.toBeNumber(),
      eventIndex: expect.toBeNumber(),
      data: {
        id,
        from,
        providerUUID: expect.any(String),
        type: 'A.179b6b1cb6755e31.' + contract + '.NFT',
        uuid: expect.any(String),
      },
    };
  },

  createExpectedDepositedEvent(contract, id, to) {
    if (!id || to === undefined) throw new Error('id and to are required');
    return {
      type: 'A.f8d6e0586b0a20c7.NonFungibleToken.Deposited',
      transactionId: expect.toBeString(),
      transactionIndex: expect.toBeNumber(),
      eventIndex: expect.toBeNumber(),
      data: {
        id,
        to,
        collectionUUID: expect.any(String),
        type: 'A.179b6b1cb6755e31.' + contract + '.NFT',
        uuid: expect.any(String),
      },
    };
  },
};

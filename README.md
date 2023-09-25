# Rails 🧙

_A Solidity framework for creating complex and evolving onchain structures._

Rails is a modular smart contract system leveraging cutting edge blockchain technology like **ERC4337 account abstraction** and **ERC6551 token bound accounts** in combination with more familiar patterns like **EIP712 signature validation** as well as **Modules**, **Access**, **Guards**, and **Extensions** to provide a comprehensive suite of onchain mechanisms for any organization.

[Get started with our documentation](https://docs.groupos.xyz/contract-architecture/framework/modules)

Rails's intuition began cultivating in mid-2021 in response to designing for modular token design and vault management problems.
Currently, Rails is being developed and applied in production for [GroupOS](https://groupos.xyz/), a protocol and product for creating autonomous networks.

## Smart Contract Architecture
For more information about the GroupOS protocol as well as our technical docs, [check out the GroupOS smart contract documentation!](https://docs.groupos.xyz/contract-architecture/overview/framework)

<img width="566" alt="image" src="https://github.com/0xStation/mage/assets/38736612/f20a4d8b-4b42-4607-ba03-fd635ff1ea94">

## Deployments

| EVM Network | ERC721Rails Address                                                                                                           |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Goerli      | [0x1fc83981028ca43ed0a95d166b7d201abe6e8195](https://goerli.etherscan.io/address/0x1fc83981028ca43ed0a95d166b7d201abe6e8195) |
| Polygon | [0x1fc83981028ca43ed0a95d166b7d201abe6e8195](https://polygonscan.com/address/0x1fc83981028ca43ed0a95d166b7d201abe6e8195) |
| Linea | [0xa03a52b4c8d0c8c64c540183447494c25f590e20](https://lineascan.build/address/0xa03a52b4c8d0c8c64c540183447494c25f590e20)

To deploy and verify [ERC721Rails](./src/cores/ERC721/ERC721Rails.sol), run:

```
forge create --private-key $PRIVATE_KEY --verify --chain-id 5 --rpc-url $GOERLI_RPC_URL --api-key $ETHERSCAN_API_KEY src/cores/ERC721/ERC721Rails.sol:ERC721Rails
```

## Contributing

While Rails is in initial R&D, assistance on reviews for security and developer experience are most appreciated. Upon first release, Rails will support public contributions and commentary and likely incorporate a token-incentive model for fun and recognition. In the meantime, please reach out directly via [Twitter DM](https://twitter.com/ilikesymmetry).

## License

Rails is a free public good and we just request attribution for code or ideas that stem from this project. Direct inquiries for using Rails in your own project via [Twitter DM](https://twitter.com/ilikesymmetry). Note that Rails is currently un-audited with plans to audit in late 2023.

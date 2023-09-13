# Rails 🧙

_A Solidity framework for creating complex and evolving onchain structures._

Rails is an acronym for the architecture pattern's four layers: **Module**, **Access**, **Guard**, and **Extension**.

Rails's intuition began cultivating in mid-2021 in response to designing for modular token design and vault management problems.
Currently, Rails is being developed and applied in production for [GroupOS](https://groupos.xyz/), a protocol and product for creating autonomous networks.

<img width="566" alt="image" src="https://github.com/0xStation/mage/assets/38736612/f20a4d8b-4b42-4607-ba03-fd635ff1ea94">

## Deployments

| EVM Network | ERC721Rails Address                                                                                                           |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Goerli      | [0x1fc83981028ca43ed0a95d166b7d201abe6e8195](https://goerli.etherscan.io/address/0x1fc83981028ca43ed0a95d166b7d201abe6e8195) |
| Polygon | [0x1fc83981028ca43ed0a95d166b7d201abe6e8195](https://polygonscan.com/address/0x1fc83981028ca43ed0a95d166b7d201abe6e8195#code)

To deploy and verify [ERC721Rails](./src/cores/ERC721/ERC721Rails.sol), run:

```
forge create --private-key $PRIVATE_KEY --verify --chain-id 5 --rpc-url $GOERLI_RPC_URL --api-key $ETHERSCAN_API_KEY src/cores/ERC721/ERC721Rails.sol:ERC721Rails
```

## Contributing

While Rails is in initial R&D, assistance on reviews for security and developer experience are most appreciated. Upon first release, Rails will support public contributions and commentary and likely incorporate a token-incentive model for fun and recognition. In the meantime, please reach out directly via [Twitter DM](https://twitter.com/ilikesymmetry).

## License

Rails is a free public good and we just request attribution for code or ideas that stem from this project. Direct inquiries for using Rails in your own project via [Twitter DM](https://twitter.com/ilikesymmetry). Note that Rails is currently un-audited with plans to audit in late 2023.

import axios from "axios";
import { ethers } from "ethers";
import Web3Modal from "Web3Modal";
import { useEffect, useState } from "react";
import styles from "../styles/Home.module.css";

import { nftaddress, nftmarketaddress } from "../config";

import NFT from "../artifacts/contracts/NFT.sol/NFT.json";
import Market from "../artifacts/contracts/NFTMarket.sol/NFTMarket.json";

export default function Home() {
  const [nfts, setNfts] = useState([]);
  const [loadingState, setLoadingState] = useState("not-loaded");

  async function loadNFTs() {
    const provider = new ethers.providers.JsonRpcProvider();

    const tokenContract = new ethers.Contract(nftaddress, NFT.abi, provider);
    const marketContract = new ethers.Contract(
      nftmarketaddress,
      Market.abi,
      provider
    );

    //returns an array of unsold market items
    const data = await marketContract.fetchMarketItems();

    const items = await Promise.all(
      data.map(async (i) => {
        const tokenUri = await tokenContract.tokenURI(i.tokenId);

        const meta = await axios.get(tokenUri);
        let price = ethers.utils.formatUnits(i.price.toString(), "ether");
        let item = {
          price,
          tokenId: i.tokentId.toNumber(),
          seller: i.seller,
          owner: i.owner,
          image: meta.data.image,
          name: meta.data.name,
          description: meta.data.description,
        };

        return item;
      })
    );

    setNfts(items);
    setLoadingState("loaded");
  }

  if (loadingState === "loaded" && !nfts.length) {
    return <h1 className="px-20 py-10 text-3xt">No items in market place</h1>;
  }

  useEffect(() => {
    loadNFTs();
  }, []);

  return (
    <div className={styles.container}>
      <h1>Welcome to home!</h1>
    </div>
  );
}

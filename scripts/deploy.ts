import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import {  PGAGEN__factory } from '../typechain';
import {  ETB__factory } from '../typechain';
import {  CakeLP__factory } from '../typechain';
import {  Migrations__factory } from '../typechain';
import {  StakingPool__factory } from '../typechain';
import {  StakingRewardPool__factory } from '../typechain';


async function main() {
  const [deployer] = await ethers.getSigners();


  const pgaNFTMarketplace = new PGAGEN__factory(deployer);
  const ETB = new ETB__factory(deployer);
  const CakeLP = new CakeLP__factory(deployer);
  const Migrations = new Migrations__factory(deployer);
  const StakingPool = new StakingPool__factory(deployer);
  const StakingReward = new StakingRewardPool__factory(deployer);

  const token = "0x33FC58F12A56280503b04AC7911D1EceEBcE179c";

  const PgaNFTMarketplace =  await pgaNFTMarketplace.deploy();
  await PgaNFTMarketplace.deployed();
  console.log('PGA Marketplace deployed to: ', PgaNFTMarketplace.address);

  const Etb =  await ETB.deploy();
  await Etb.deployed();
  console.log('Etb deployed to: ', Etb.address);

  const Cake =  await CakeLP.deploy();
  await Cake.deployed();
  console.log('Cake deployed to: ', Cake.address);

  const Migration =  await Migrations.deploy();
  await Migration.deployed();
  console.log('Miggrations deployed to: ', Migration.address);

  const Stakingpool =  await StakingPool.deploy(token, token);
  await Stakingpool.deployed();
  console.log('starking Pool deployed to: ', Stakingpool.address);


  const Stakingreward =  await StakingReward.deploy(token, token);
  await Stakingreward.deployed();
  console.log('starking Reward deployed to: ', Stakingreward.address);

  
  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;

})
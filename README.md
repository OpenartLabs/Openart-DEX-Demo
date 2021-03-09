# OpenMart-DEX-Demo
OpenMart 协议中的一口价交易合约、竞拍合约等基础功能的 Demo。

## AuctionContract

拍卖合约，使用拍卖即使交换商品。内部实现增加拍卖、竞拍、竞拍成功、修改竞拍信息、下架竞拍，五个操作方法。

### 增加拍卖

```
function addAuction(address tokenAddress, 
		                uint256 tokenId, 
		                uint256 time, 
		                uint256 startAmount,
		                uint256 amountSpan, 
		                uint256 incentive, 
		                string memory data) public noContract
```

输入参数 | 描述
---|---
tokenAddress | ERC721地址
tokenId| ERC721 ID
time | 拍卖持续时间
startAmount| 起拍价
amountSpan| 拍卖最小价格差
incentive| 激励比例，0%~20%
data| 商品描述

### 竞拍

```
function continueBidding(uint256 index, uint256 amount) public payable noContract
```

输入参数 | 描述
---|---
index | 拍卖编号
amount| 出价

### 竞拍成功，交易

```
function auctionSuccess(uint256 index) public noContract
```

输入参数 | 描述
---|---
index | 拍卖编号

### 修改竞拍信息

```
function modifyInformation(uint256 index,
		                       uint256 time, 
		                	   uint256 startAmount,
		                       uint256 amountSpan, 
		                       uint256 incentive, 
		                       string memory data) public noContract
```


输入参数 | 描述
---|---
index | 拍卖编号
time | 拍卖持续时间
startAmount| 起拍价
amountSpan| 拍卖最小价格差
incentive| 激励比例，0%~20%
data| 商品描述

### 下架竞拍

```
function subAuction(uint256 index) public noContract
```

输入参数 | 描述
---|---
index | 拍卖编号







## ExchangeContract

一口价合约，内部实现增加商品、修改商品、购买商品、下架商品，四个操作方法。

### 增加商品

```
function addGoods(address _tokenAddress, 
		              uint256 _tokenId, 
		              uint256 _ethAmount,
		              string memory data) public onContract
```


输入参数 | 描述
---|---
_tokenAddress | ERC721地址
_tokenId | ERC721 ID
_ethAmount | 商品价格
data | 商品描述

### 修改商品

```
function changeGoods(uint256 index, 
		                 uint256 ethAmount, 
		                 string memory data) public onContract
```

输入参数 | 描述
---|---
index | 订单编号
_ethAmount | 商品价格
data | 商品描述

### 购买商品

```
function buyGoods(uint256 index) public payable onContract
```

输入参数 | 描述
---|---
index | 订单编号

### 下架商品

```
function subGoods(uint256 index) public onContract
```

输入参数 | 描述
---|---
index | 订单编号

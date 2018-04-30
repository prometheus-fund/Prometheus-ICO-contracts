# Prometheus-ICO-contracts
This is a source code of smart-contracts which will be used in Prometheus ICO

##Oracul
Oracul gets info about exchange rate ethereum/usd from "Kraken" S.E.
https://api.kraken.com/0/public/Ticker?pair=ETHUSD

##Prometheus token
Prometheus token realize all functionality of standard ERC20 token.
Additional features:
* This tokens cannot be transfer and approve during pre-ICO and ICO (they will be unlocked only after successful ending of ICO)
* Tokens can be "burnt" if not sold

##Prometheus pre-ICO & ICO
* Cost in ether depends on USD (exchange rate is provided by oracul contract)
* Both pre-ICO and ICO have bonus program (for major purchases)
* If soft cap won't be reached during pre-ICO or ICO byers can return their money back (excluding transaction costs) in limited time span

## Deployment steps:
1. Deployment of oracul contract
2. Deployment of token contract
3. Deployment of ICO contract
4. Deployment of pre-ICO contract
5. Call of function SetICOContracts in token contract
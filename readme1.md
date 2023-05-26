Curl

curl -X 'GET' \
 'https://legend.lnbits.com/api/v1/payments?limit=100&api-key=b86dacdf0d8a449193230ff47093d5ad' \
 -H 'accept: application/json' \
 -H 'X-API-KEY: b86dacdf0d8a449193230ff47093d5ad'
Request URL
https://legend.lnbits.com/api/v1/payments?limit=100&api-key=b86dacdf0d8a449193230ff47093d5ad
Server response
Code Details
200
Response body
Download
[
{
"checking_id": "internal_f1bbe0aa45fca05f3100668d4ec2cddb650f5fc9a46a62ad81318d943368fcc5",
"pending": false,
"amount": -100000,
"fee": 0,
"memo": "Test",
"time": 1684393735,
"bolt11": "lnbc1u1pjxtncrsp57gh2ehguy4ypzyh2py73juq8s46vhpu7x6dpzdqyvfgj68zlw2fspp57xa7p2j9ljs97vgqv6x5askdmdjs7h7f534x9tvpxxxegvmglnzsdq823jhxaqxqzjccqpjrzjqvy526u0n054h243l70xg8sar8dpjqz00en2cce582vn7xnyr2lfzrq9zuqqv2qqqsqqqqqqqqqqqqcq9q9qyysgqpkzeegsezt5k3qqfjcj4dnflvynjpnekjf0pqfvaymc5p64ss9w5m5wk9et957yuq2j6vg5qns6x8sf3600ehke8pgdz0vftkv2k09qpt5lp8c",
"preimage": "0000000000000000000000000000000000000000000000000000000000000000",
"payment_hash": "f1bbe0aa45fca05f3100668d4ec2cddb650f5fc9a46a62ad81318d943368fcc5",
"expiry": 1684394331,
"extra": {},
"wallet_id": "aa1728acff604222a96d1343f9246c12",
"webhook": null,
"webhook_status": null
},

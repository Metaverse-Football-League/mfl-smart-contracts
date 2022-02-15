# Starting Index

## Problem to solve

MFL players can have various stats, making some players better than others. As a result, some players will have more value than others. Players will be sold in packs. These packs will be randomly generated with different chances of dropping high-tier players. 

We want to make sure that when someone buys a pack he doesn't know which players he will get. If so, he could use this knowledge to his advantage to buy specific packs with the best players. 

Even if this risk is very limited (only the MFL team will be able to know packs content) we decided to set up a specific process to prevent anyone from having an unfair advantage on the drop. 

Transparency, fairness, and trust by our community are fundamental pillars to us.

## Solution

As explained above, the aim of the implemented solution is to make sure that the buyer doesn't know which players he will get in the pack he buys.

Here is how we implemented this solution:

- For each pack drop, a CSV is created. Each line describes the content of a pack. This CSV is hashed and this hash is publicly released before the drop.
- When someone buys a pack, we increment a counter to determine at which position he bought it. This position is used to determine the line in the CSV, allowing us to know the players contained in the pack. For example, if I buy the third pack, I will get the players listed at the third line of the CSV.
- If we were only doing that, someone with access to the CSV could easily target some packs (buy at a specific position) and get the players he wants. That’s why we added the Starting Index.
- This Starting Index will offset the index of the CSV line (used to describe the content of the pack). Since nothing is really random on the blockchain, we couldn’t generate a random number. We chose to compute this Starting Index based on all the wallet addresses that bought a pack.
- As it is not possible to control all the wallet addresses that will buy a pack, we will get a starting index not predictable and on which no one has control. A real fair drop!
- When the drop is completed, we will reveal the private hash key of the CSV for anyone to be able to verify the content of this file.

## How the Starting Index is incremented

Now, let’s have a quick look at how the Starting Index is calculated and incremented. 

For each user transaction (buying packs), we use the wallet address and proceed with the following operations:

1. Sum the four UInt32 components of the address.
2. Add the sum to the starting index.
3. Modulo the starting index with the max supply of the pack drop (to stay in the range of what's possible).

The final value of the starting index is determined, once the packs are sold out. Only at this moment, the owners will be able to open their packs and receive the content of the pack. 

In the case we want users to open their pack before the entire pack drop is sold out (to improve user experience), we will be able to freeze the Starting Index at a specific date and time.

## Conclusion

We put a lot of thought and time into designing and implementing this complex process. Even though this kind of process is not required (and not done by most projects), we decided to do it to ensure the most transparent and fair drop to our community. 

However, the above process is not 100% perfect. Indeed, in the case the Starting Index has been frozen before the end of the drop, it could be possible to use insider information to take advantage of the drop. We will try as much as possible to wait for the pack drop to sell out (vs freezing the Starting Index). However, that might not be always possible. We also want our users to get a great user experience and be able to open their packs not too long after buying them.

We are thinking of ways to keep improving this process. In the meantime, we hope this process will show our community that we are taking integrity, fairness, and transparency very seriously. Even if we like to believe that we are a trustworthy team, it is even better if there is no possible way for anyone to use insider information. Can’t > Won’t.
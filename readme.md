# Ascend #

I have decided to release our source due to some retards bypassing my remote security (which I removed from this release) & leaking the method

Here is why this method works (credits to Ancestor for finding it originally):
![image](https://github.com/x0x37x/ascend-public-files/assets/138546622/2f2b21bc-7d44-4654-9df0-d1e941172977)
The 3rd param of request load (params: player, slot number, loadOtherPlayerId) is not sanitized on the server, if you pass a table with your user id in it, it will load your base on the server, however will not realize it is infact your base

Defaultio (the creator of the game) added this parameter so he could test loading while developing the game.

a simple typeof(loadOtherPlayerId) ~= "table" would fix this. Or better yet, don't have that there, there is literally NO reason for it.

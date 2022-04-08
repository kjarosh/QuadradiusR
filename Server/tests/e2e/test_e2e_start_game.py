import asyncio
from unittest import IsolatedAsyncioTestCase

import aiohttp
from async_timeout import timeout

from harness import TestUserHarness, RestTestHarness


class E2eStartGameTest(IsolatedAsyncioTestCase, TestUserHarness, RestTestHarness):

    async def asyncSetUp(self) -> None:
        await self.setup_server()

    async def asyncTearDown(self) -> None:
        await self.shutdown_server()

    async def test_start_game(self):
        # * user0 sends invite to user1
        # * user1 accepts the invite
        # * user0 receives notification
        # * both users join the game

        await asyncio.gather(
            self.create_test_user(0),
            self.create_test_user(1),
        )

        user1 = await self.get_test_user(1)

        async with timeout(2), aiohttp.ClientSession() as session:
            async with session.post(self.server_url('/game_invite'), json={
                'subject_id': user1['id'],
            }, headers={
                'authorization': await self.authorize_test_user(0)
            }) as response:
                self.assertEqual(201, response.status)
                game_invite_path = response.headers['location']

            async with session.post(self.server_url(game_invite_path + '/accept'), headers={
                'authorization': await self.authorize_test_user(1)
            }, allow_redirects=False) as response:
                self.assertEqual(303, response.status)
                game_path = response.headers['location']

            game_ws = self.server_url(game_path + '/connect', protocol='ws')

            async with session.ws_connect(game_ws) as ws0, \
                    session.ws_connect(game_ws) as ws1:
                await asyncio.gather(
                    self.authorize_ws(0, ws0),
                    self.authorize_ws(1, ws1),
                )

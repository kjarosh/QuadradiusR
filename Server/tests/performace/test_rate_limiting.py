import time
import uuid
from asyncio import TimeoutError
from datetime import timedelta, datetime
from unittest import IsolatedAsyncioTestCase

import aiohttp
from async_timeout import timeout

from harness import TestUserHarness, RestTestHarness


class TestRateLimiting(IsolatedAsyncioTestCase, TestUserHarness, RestTestHarness):

    async def asyncSetUp(self) -> None:
        await self.setup_server()

    async def asyncTearDown(self) -> None:
        await self.shutdown_server()

    async def create_user(self, session):
        async with session.post(self.server_url('/user'), json={
            'username': f'user{uuid.uuid4()}',
            'password': f'password{uuid.uuid4()}',
        }) as response:
            return 201 == response.status

    async def test_create_user(self):
        async with aiohttp.ClientSession() as session:
            requests = 0
            start_time = time.time()
            deadline = datetime.now() + timedelta(seconds=10)
            while datetime.now() < deadline:
                if await self.create_user(session):
                    requests += 1
            all_time = time.time() - start_time
            print(f'{requests / all_time} req/s')

import datetime
import uuid
from typing import Dict

from quadradiusr_server.db.base import Lobby, User, LobbyMessage
from quadradiusr_server.db.database_engine import DatabaseEngine
from quadradiusr_server.db.repository import Repository
from quadradiusr_server.notification import NotificationService
from quadradiusr_server.qrws_connection import BasicConnection, QrwsConnection
from quadradiusr_server.qrws_messages import Message, SendMessageMessage, MessageSentMessage


class LiveLobby:
    def __init__(self, lobby: Lobby, repository: Repository) -> None:
        self.lobby = lobby
        self.repository = repository

        self.players: Dict[str, LobbyConnection] = {}

    def join(self, connection: 'LobbyConnection'):
        if connection.user.id_ in self.players:
            raise Exception()
        self.players[connection.user.id_] = connection

    def leave(self, lobby_conn: 'LobbyConnection'):
        if lobby_conn in self.players.values():
            del self.players[lobby_conn.user.id_]

    async def send_message(self, user: User, content: str):
        lobby_repo = self.repository.lobby_repository
        lobby_message = LobbyMessage(
            id_=str(uuid.uuid4()),
            user_id_=user.id_,
            lobby_id_=self.lobby.id_,
            content_=content,
            created_at_=datetime.datetime.now(),
        )
        await lobby_repo.add_message(lobby_message)
        for conn in self.players.values():
            await conn.message_sent(user, content)

    def joined(self, user: User):
        return user.id_ in self.players.keys()


class LobbyConnection(BasicConnection):

    def __init__(
            self, lobby: LiveLobby,
            qrws: QrwsConnection,
            user: User,
            notification_service: NotificationService,
            database: DatabaseEngine) -> None:
        super().__init__(qrws, user, notification_service, database)
        self.lobby: LiveLobby = lobby

    async def handle_message(self, message: Message) -> bool:
        if await super().handle_message(message):
            return True

        if isinstance(message, SendMessageMessage):
            content = message.content
            await self.lobby.send_message(self.user, content)
            return True
        else:
            return False

    async def message_sent(self, user, content):
        await self.qrws.send_message(MessageSentMessage(
            user_id=user.id_,
            content=content,
        ))

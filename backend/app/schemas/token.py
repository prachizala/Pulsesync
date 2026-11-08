from typing import Optional
from pydantic import BaseModel


class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    user_id: int
    email: str


class TokenPayload(BaseModel):
    sub: Optional[str] = None
    role: Optional[str] = None

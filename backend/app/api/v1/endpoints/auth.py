from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user, require_roles
from app.core.security import get_password_hash, verify_password, create_access_token
from app.models.user import User, UserRole
from app.schemas.token import Token
from app.schemas.user import UserCreate, UserResponse

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> Any:
    """Register a new user (responder by default or specified role)."""
    result = await db.execute(select(User).where(User.email == user_in.email))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists.",
        )

    user = User(
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        full_name=user_in.full_name,
        role=user_in.role.value,
        is_active=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/login/access-token", response_model=Token)
async def login_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
) -> Any:
    """OAuth2 compatible token login, retrieve access token for future requests."""
    result = await db.execute(select(User).where(User.email == form_data.username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password",
        )
    elif not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user account",
        )

    access_token = create_access_token(subject=user.id, role=user.role)
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "user_id": user.id,
        "email": user.email,
    }


@router.get("/me", response_model=UserResponse)
async def read_user_me(
    current_user: User = Depends(get_current_user),
) -> Any:
    """Get current logged in user profile."""
    return current_user


@router.get("/users", response_model=List[UserResponse])
async def list_users(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN.value, UserRole.DISPATCHER.value])),
) -> Any:
    """List all registered users (dispatcher/admin only)."""
    result = await db.execute(select(User).order_by(User.id))
    return result.scalars().all()

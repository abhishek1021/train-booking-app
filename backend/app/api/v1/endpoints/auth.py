# from datetime import timedelta
# from typing import Any
# from fastapi import APIRouter, Depends, HTTPException, status
# from fastapi.security import OAuth2PasswordRequestForm
# from sqlalchemy.orm import Session

# # from app.core.config import settings
# from app.core import security
# from app.db.session import get_db
# from app.schemas.auth import Token, UserCreate, User
# from app.crud import user as crud_user

# router = APIRouter()

# @router.post("/login", response_model=Token)
# def login(
#     db: Session = Depends(get_db),
#     form_data: OAuth2PasswordRequestForm = Depends()
# ) -> Any:
#     """
#     OAuth2 compatible token login, get an access token for future requests
#     """
#     user = crud_user.authenticate(
#         db, email=form_data.username, password=form_data.password
#     )
#     if not user:
#         raise HTTPException(
#             status_code=status.HTTP_401_UNAUTHORIZED,
#             detail="Incorrect email or password",
#         )
#     elif not user.is_active:
#         raise HTTPException(
#             status_code=status.HTTP_401_UNAUTHORIZED,
#             detail="Inactive user",
#         )
#     # access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
#     access_token_expires = timedelta(minutes=30)  # Default/fallback value
#     return {
#         "access_token": security.create_access_token(
#             user.id, expires_delta=access_token_expires
#         ),
#         "token_type": "bearer",
#     }

# @router.post("/register", response_model=User)
# def register(
#     *,
#     db: Session = Depends(get_db),
#     user_in: UserCreate,
# ) -> Any:
#     """
#     Create new user
#     """
#     user = crud_user.get_by_email(db, email=user_in.email)
#     if user:
#         raise HTTPException(
#             status_code=status.HTTP_400_BAD_REQUEST,
#             detail="Email already registered",
#         )
#     user = crud_user.create(db, obj_in=user_in)
#     return user

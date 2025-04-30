from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# from app.core.config import settings

# engine = create_engine(settings.DATABASE_URL)
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    raise NotImplementedError("Database is not configured. This function should not be used.")

import os
from pydantic_settings import BaseSettings
from .db import DatabaseSettings

class Settings(DatabaseSettings):
    project_name: str = "stock_backend"
    debug: bool = False
    secret_key: str = "change-me-in-production"
    
    # Redis settings
    redis_url: str = "redis://localhost:6379/0"
    
    # Celery settings  
    celery_broker: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/0"
    
    # Development settings
    is_dev: bool = False
    create_test_data: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = False
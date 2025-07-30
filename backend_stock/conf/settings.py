from .db import DatabaseSettings


class Settings(DatabaseSettings):
    project_name: str = "backend_stock"
    debug: bool = False

import os
from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles

from .api.routes import router

app = FastAPI(
    title="Stock Backend API",
    description="Stock market data processing API",
    version="1.0.0"
)

# Include API routes
app.include_router(router, prefix="/api/v1")

static_file_path = os.path.dirname(os.path.realpath(__file__)) + "/static"
app.mount("/static", StaticFiles(directory=static_file_path), name="static")

@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse("/docs")
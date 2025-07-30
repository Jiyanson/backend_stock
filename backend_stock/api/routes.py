# stock_backend/api/routes.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from ..services.db import get_session_depends
from ..models.stock import Stock
from ..celery import process_stock_data

router = APIRouter()

@router.get("/stocks", response_model=List[dict])
async def get_stocks(session: AsyncSession = Depends(get_session_depends)):
    """Get all stocks"""
    result = await session.execute(select(Stock))
    stocks = result.scalars().all()
    return [{"id": s.id, "symbol": s.symbol, "name": s.name, "price": s.price} for s in stocks]

@router.post("/stocks/{symbol}/process")
async def process_stock(symbol: str):
    """Trigger background processing for a stock"""
    task = process_stock_data.delay(symbol)
    return {"task_id": task.id, "status": "processing", "symbol": symbol}

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "stock_backend"}
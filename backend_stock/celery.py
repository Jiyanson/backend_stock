import os
from celery import Celery

# Get broker URL from environment or default to Redis
broker_url = os.getenv('CELERY_BROKER', 'redis://localhost:6379/0')
result_backend = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

celery = Celery(
    "stock_backend",
    broker=broker_url,
    backend=result_backend,
    include=['stock_backend.celery']
)

# Celery configuration
celery.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    beat_schedule={
        'hello-every-15-seconds': {
            'task': 'stock_backend.celery.hello_world',
            'schedule': 15.0,
        },
    },
)

@celery.task
def hello_world():
    print("Hello World from Celery!")
    return "Task completed successfully"

# Additional useful tasks
@celery.task
def process_stock_data(symbol: str):
    """Example task for processing stock data"""
    print(f"Processing stock data for {symbol}")
    # Add your stock processing logic here
    return f"Processed {symbol}"
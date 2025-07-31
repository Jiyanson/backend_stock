#!/bin/bash

echo "🔧 Fixing file permissions for Docker..."

# Make sure all files are readable by Docker
sudo chmod -R 755 ./backend_stock
sudo chmod -R 755 ./db
sudo chmod 644 ./alembic.ini
sudo chmod 644 ./pyproject.toml
sudo chmod 644 ./requirements.txt

echo "📁 Current permissions:"
ls -la ./backend_stock
ls -la ./

echo "🛑 Stopping containers..."
sudo docker-compose down

echo "🧹 Cleaning up..."
sudo docker-compose rm -f

echo "🏗️ Rebuilding..."
sudo docker-compose build --no-cache

echo "🚀 Starting containers..."
sudo docker-compose up -d

echo "⏳ Waiting for containers to start..."
sleep 10

echo "📋 Container status:"
sudo docker-compose ps

echo "📝 WWW container logs:"
sudo docker-compose logs www
#!/bin/bash

# Backend Validation Test Script
# Tests all validation endpoints with valid and invalid data

BASE_URL="http://localhost:3000/api"

echo "================================"
echo "Testing Backend Input Validation"
echo "================================"
echo ""

# Test 1: Registration with invalid name (contains numbers)
echo "Test 1: Registration with invalid name (contains numbers)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John123",
    "email": "test@example.com",
    "password": "Test1234",
    "phone": "9876543210"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 2: Registration with invalid email
echo "Test 2: Registration with invalid email"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "invalid-email",
    "password": "Test1234",
    "phone": "9876543210"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 3: Registration with invalid phone (contains letters)
echo "Test 3: Registration with invalid phone (contains letters)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "test@example.com",
    "password": "Test1234",
    "phone": "98765abc10"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 4: Registration with weak password (no uppercase)
echo "Test 4: Registration with weak password (no uppercase)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "test@example.com",
    "password": "test1234",
    "phone": "9876543210"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 5: Registration with weak password (no lowercase)
echo "Test 5: Registration with weak password (no lowercase)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "test@example.com",
    "password": "TEST1234",
    "phone": "9876543210"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 6: Registration with weak password (no number)
echo "Test 6: Registration with weak password (no number)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "test@example.com",
    "password": "TestPass",
    "phone": "9876543210"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 7: Registration with weak password (too short)
echo "Test 7: Registration with weak password (too short)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "test@example.com",
    "password": "Test12",
    "phone": "9876543210"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 8: Registration with invalid phone length
echo "Test 8: Registration with invalid phone length (too short)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "test@example.com",
    "password": "Test1234",
    "phone": "98765"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 9: Valid registration (should succeed)
echo "Test 9: Valid registration (should succeed)"
curl -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "validuser@example.com",
    "password": "Test1234",
    "phone": "+919876543210",
    "role": "resident"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 10: Login with invalid email
echo "Test 10: Login with invalid email"
curl -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "invalid-email",
    "password": "Test1234"
  }' \
  -w "\nStatus: %{http_code}\n\n"

# Test 11: Valid login (should succeed)
echo "Test 11: Valid login (should succeed)"
curl -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "validuser@example.com",
    "password": "Test1234"
  }' \
  -w "\nStatus: %{http_code}\n\n"

echo "================================"
echo "All tests completed!"
echo "================================"

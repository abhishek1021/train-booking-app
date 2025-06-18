import pytest
import jwt
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from app.core.jwt import create_jwt_token, decode_jwt_token, JWT_SECRET, JWT_ALGORITHM

# Test JWT token creation and validation
def test_jwt_token_creation():
    # Create test data
    test_data = {
        "user_id": "test123",
        "email": "test@example.com",
        "username": "testuser",
        "role": "user"
    }
    
    # Create token
    token = create_jwt_token(test_data)
    
    # Verify token is a string
    assert isinstance(token, str)
    
    # Decode token and verify data
    decoded = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    
    # Check if all data is present in decoded token
    for key, value in test_data.items():
        assert decoded[key] == value
    
    # Check if expiration is set
    assert "exp" in decoded

# Test token expiration
def test_token_expiration():
    # Create test data with manual expiration (1 second in the past)
    test_data = {
        "user_id": "test123",
        "email": "test@example.com",
        "exp": datetime.utcnow() - timedelta(seconds=1)
    }
    
    # Create expired token
    token = jwt.encode(test_data, JWT_SECRET, algorithm=JWT_ALGORITHM)
    
    # Verify decoding raises an exception
    with pytest.raises(Exception):
        decode_jwt_token(token)

# Test invalid token
def test_invalid_token():
    # Create an invalid token
    invalid_token = "invalid.token.string"
    
    # Verify decoding raises an exception
    with pytest.raises(Exception):
        decode_jwt_token(invalid_token)

# Integration test with FastAPI app (requires app fixture)
def test_protected_endpoint(test_client):
    # This test requires a fixture that provides a TestClient for your FastAPI app
    # Create test data
    test_data = {
        "user_id": "test123",
        "email": "test@example.com",
        "username": "testuser",
        "role": "user"
    }
    
    # Create token
    token = create_jwt_token(test_data)
    
    # Make request to protected endpoint
    response = test_client.get(
        "/api/v1/auth/auth-test",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    # Verify response
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == test_data["user_id"]
    assert data["email"] == test_data["email"]

# Test unauthorized access
def test_unauthorized_access(test_client):
    # Make request without token
    response = test_client.get("/api/v1/auth/auth-test")
    
    # Verify response
    assert response.status_code == 401

# Fixture for TestClient (to be used with pytest)
@pytest.fixture
def test_client():
    from main import app
    return TestClient(app)

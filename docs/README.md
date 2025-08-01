# Glyfs API Documentation

Welcome to the Glyfs API documentation. This guide will help you integrate with Glyfs' powerful AI glyf platform programmatically.

## Quick Start

1. **Create a Glyf** - Set up your AI glyf through the web interface
2. **Generate API Key** - Create an API key for your glyf
3. **Make API Calls** - Use the API key to interact with your glyf

## API Overview

Glyfs provides two main API endpoints for interacting with your glyfs:

- **[Invoke API](./invoke-api.md)** - Get complete responses in a single request
- **[Streaming API](./streaming-api.md)** - Get real-time streaming responses

## Authentication

All API requests require authentication using API keys. Include your API key in the `Authorization` header:

```bash
Authorization: Bearer apk_your_api_key_here
```

## Base URL

All API endpoints are relative to your Glyfs instance:

```
https://your-glyfs-instance.com/api
```

## Rate Limits

API requests are subject to rate limiting based on your plan. Contact support for enterprise rate limits.

## Error Handling

The API uses standard HTTP status codes and returns JSON error messages:

```json
{
  "message": "Error description"
}
```

Common status codes:
- `200` - Success
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (invalid API key)
- `404` - Not Found (glyf doesn't exist)
- `500` - Internal Server Error

## Support

For API support, please:
- Check the documentation sections
- Review the examples provided
- Contact support for enterprise customers

## Documentation Sections

- [Invoke API](./invoke-api.md) - Single request/response API
- [Streaming API](./streaming-api.md) - Real-time streaming API
- [Examples](./examples.md) - Code examples in multiple languages
- [Tools & MCP](./tools.md) - Working with glyf tools and MCP servers
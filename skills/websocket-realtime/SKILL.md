---
name: websocket-realtime
description: WebSocket and Server-Sent Events implementation patterns for real-time features. Covers connection lifecycle, reconnection with backoff, backpressure, authentication, presence systems, and scaling across multiple server instances. Use when implementing chat, live updates, collaborative features, streaming LLM responses, or any feature requiring server-push communication.
---

# WebSocket & Real-Time

This skill covers the server and client patterns for WebSocket and SSE connections in production — beyond the happy path.

## When to Use

- Implementing chat, live notifications, or collaborative editing
- Streaming LLM responses to the frontend (SSE is ideal for this)
- Building presence indicators (who is online, who is typing)
- Any feature where the server needs to push updates to clients without polling
- An existing WebSocket implementation is dropping connections or failing under load

## When NOT to Use

- Simple polling for infrequent updates — polling is simpler and sufficient for < 1 update/minute
- Webhook delivery to other servers — use HTTP POST callbacks
- Background job status that is checked once — use a regular REST endpoint

## Protocol Choice

| Use Case | Protocol | Reason |
|---|---|---|
| LLM streaming responses | **SSE** | Unidirectional, works through HTTP/2, trivial reconnect |
| Live document updates | **SSE** | Read-only server push, simpler than WS |
| Chat, collaborative editing | **WebSocket** | Bidirectional — client also sends data |
| Presence, typing indicators | **WebSocket** | Bidirectional — client sends state |
| Progress bars, dashboards | **SSE** | Unidirectional push, no client messages |

SSE runs over HTTP — no special proxy config, works through load balancers out of the box. WebSocket requires `Upgrade` header support (most modern load balancers support this).

## Server-Sent Events (SSE)

SSE is the right choice for LLM streaming and unidirectional server push:

**NestJS / Express SSE endpoint:**
```typescript
@Get('stream/:id')
@Sse()
streamDocument(@Param('id') id: string, @Req() req: Request): Observable<MessageEvent> {
  return new Observable((observer) => {
    const stream = this.documentService.streamAnalysis(id);

    stream.on('data', (chunk: string) => {
      observer.next({ data: JSON.stringify({ content: chunk }) });
    });

    stream.on('end', () => {
      observer.next({ data: JSON.stringify({ done: true }) });
      observer.complete();
    });

    stream.on('error', (err) => {
      observer.next({ data: JSON.stringify({ error: err.message }) });
      observer.complete();
    });

    // Clean up on client disconnect
    req.on('close', () => stream.destroy());
  });
}
```

**FastAPI SSE endpoint (for thesis streaming):**
```python
from fastapi import Request
from fastapi.responses import StreamingResponse
import asyncio

@router.get("/documents/{doc_id}/stream")
async def stream_analysis(doc_id: str, request: Request):
    async def event_generator():
        async for chunk in document_service.stream_analysis(doc_id):
            if await request.is_disconnected():
                break
            yield f"data: {json.dumps({'content': chunk})}\n\n"
        yield f"data: {json.dumps({'done': True})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",   # disable nginx buffering
        },
    )
```

**SSE client with automatic reconnect:**
```typescript
function createSSEConnection(url: string, onMessage: (data: unknown) => void) {
  const eventSource = new EventSource(url, { withCredentials: true });

  eventSource.onmessage = (e) => {
    const data = JSON.parse(e.data);
    if (data.done) {
      eventSource.close();
      return;
    }
    onMessage(data);
  };

  eventSource.onerror = () => {
    // EventSource reconnects automatically — onerror does not mean permanent failure
    // Only close explicitly when done or auth fails
  };

  return () => eventSource.close(); // cleanup function
}
```

The browser's `EventSource` API reconnects automatically with the `Last-Event-ID` header — no manual retry logic needed for basic cases.

## WebSocket

### Server (Node.js with `ws` library)

```typescript
import { WebSocketServer, WebSocket } from 'ws';
import { IncomingMessage } from 'http';

const wss = new WebSocketServer({ noServer: true });

// Connection map for broadcasting
const connections = new Map<string, Set<WebSocket>>();

wss.on('connection', (ws: WebSocket, req: IncomingMessage, userId: string) => {
  // Register connection
  if (!connections.has(userId)) connections.set(userId, new Set());
  connections.get(userId)!.add(ws);

  // Heartbeat — detect stale connections
  (ws as any).isAlive = true;
  ws.on('pong', () => { (ws as any).isAlive = true; });

  ws.on('message', (raw) => {
    try {
      const message = JSON.parse(raw.toString());
      handleMessage(ws, userId, message);
    } catch {
      ws.send(JSON.stringify({ error: 'Invalid JSON' }));
    }
  });

  ws.on('close', () => {
    connections.get(userId)?.delete(ws);
    if (connections.get(userId)?.size === 0) connections.delete(userId);
  });

  ws.on('error', (err) => {
    logger.error('WebSocket error', { userId, error: err.message });
    ws.terminate();
  });
});

// Heartbeat interval — terminate stale connections
const heartbeat = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!(ws as any).isAlive) return ws.terminate();
    (ws as any).isAlive = false;
    ws.ping();
  });
}, 30_000);

wss.on('close', () => clearInterval(heartbeat));
```

### WebSocket Upgrade (HTTP server integration)

```typescript
httpServer.on('upgrade', async (req, socket, head) => {
  try {
    // Authenticate before upgrading
    const userId = await authenticateWebSocketRequest(req);
    if (!userId) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }

    wss.handleUpgrade(req, socket, head, (ws) => {
      wss.emit('connection', ws, req, userId);
    });
  } catch {
    socket.destroy();
  }
});
```

**Never skip authentication on WebSocket upgrade.** The upgrade happens before any application-level auth middleware.

### Client with Reconnection

```typescript
class ReconnectingWebSocket {
  private ws: WebSocket | null = null;
  private reconnectDelay = 1000;
  private maxDelay = 30_000;
  private shouldReconnect = true;

  constructor(
    private url: string,
    private onMessage: (data: unknown) => void,
  ) {
    this.connect();
  }

  private connect() {
    this.ws = new WebSocket(this.url);

    this.ws.onopen = () => {
      this.reconnectDelay = 1000; // reset on successful connection
    };

    this.ws.onmessage = (e) => {
      this.onMessage(JSON.parse(e.data));
    };

    this.ws.onclose = (e) => {
      if (!this.shouldReconnect || e.code === 1008) return; // 1008 = policy violation (auth fail)
      const jitter = Math.random() * 500;
      setTimeout(() => this.connect(), this.reconnectDelay + jitter);
      this.reconnectDelay = Math.min(this.reconnectDelay * 2, this.maxDelay);
    };

    this.ws.onerror = () => {
      // onerror always precedes onclose — handle reconnect in onclose
    };
  }

  send(data: unknown) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
    }
    // Drop silently if not connected — or queue if the app needs guaranteed delivery
  }

  close() {
    this.shouldReconnect = false;
    this.ws?.close(1000);
  }
}
```

Reconnection rules:
- Exponential backoff with jitter (prevents thundering herd after server restart)
- Do not reconnect on auth failure (code 1008) — it will never succeed
- Cap at 30s max delay
- Reset delay on successful connection

## Backpressure

When the server produces data faster than the client can consume, the WebSocket send buffer fills up. Unchecked, this causes memory exhaustion.

```typescript
function safeSend(ws: WebSocket, data: unknown): boolean {
  if (ws.readyState !== WebSocket.OPEN) return false;

  // bufferedAmount is the bytes queued but not yet sent
  if (ws.bufferedAmount > 1024 * 1024) { // 1MB threshold
    logger.warn('WebSocket backpressure — dropping message', {
      bufferedAmount: ws.bufferedAmount,
    });
    return false;
  }

  ws.send(JSON.stringify(data));
  return true;
}
```

For high-throughput streams, implement a draining loop:
```typescript
async function drainSend(ws: WebSocket, messages: unknown[]) {
  for (const msg of messages) {
    ws.send(JSON.stringify(msg));
    if (ws.bufferedAmount > 512 * 1024) {
      // Wait for drain before continuing
      await new Promise<void>((resolve) => ws.once('drain', resolve));
    }
  }
}
```

## Presence System

Track who is online and propagate state changes:

```typescript
class PresenceManager {
  // roomId → Map<userId, { lastSeen, metadata }>
  private rooms = new Map<string, Map<string, PresenceEntry>>();

  join(roomId: string, userId: string, metadata: Record<string, unknown>) {
    if (!this.rooms.has(roomId)) this.rooms.set(roomId, new Map());
    this.rooms.get(roomId)!.set(userId, { lastSeen: Date.now(), metadata });
    this.broadcast(roomId, { type: 'presence', userId, status: 'online', metadata });
  }

  leave(roomId: string, userId: string) {
    this.rooms.get(roomId)?.delete(userId);
    if (this.rooms.get(roomId)?.size === 0) this.rooms.delete(roomId);
    this.broadcast(roomId, { type: 'presence', userId, status: 'offline' });
  }

  private broadcast(roomId: string, message: unknown) {
    const room = this.rooms.get(roomId);
    if (!room) return;
    const payload = JSON.stringify(message);
    for (const [uid] of room) {
      getConnectionsForUser(uid)?.forEach((ws) => {
        if (ws.readyState === WebSocket.OPEN) ws.send(payload);
      });
    }
  }
}
```

## Scaling Across Instances

A single WebSocket server cannot broadcast to connections held by other instances. Use Redis pub/sub to fan out:

```typescript
import { createClient } from 'redis';

const publisher = createClient({ url: process.env.REDIS_URL });
const subscriber = createClient({ url: process.env.REDIS_URL });

await publisher.connect();
await subscriber.connect();

// Subscribe to messages for this server's connections
await subscriber.subscribe('ws:broadcast', (message) => {
  const { roomId, payload } = JSON.parse(message);
  broadcastToLocalConnections(roomId, payload);
});

// Publish from any instance — all instances receive it
async function broadcastToRoom(roomId: string, payload: unknown) {
  await publisher.publish('ws:broadcast', JSON.stringify({ roomId, payload }));
}
```

For production scale: use `socket.io` with `@socket.io/redis-adapter` which handles this pattern including room management.

## WebSocket / SSE Checklist

```
Connection:
- [ ] Authentication before upgrade (not inside message handler)
- [ ] Heartbeat/ping-pong to detect stale connections
- [ ] Graceful close on server shutdown (drain before kill)

Client:
- [ ] Reconnection with exponential backoff + jitter
- [ ] No reconnect on auth failure (1008)
- [ ] Cleanup on component unmount

Backpressure:
- [ ] bufferedAmount checked before sending
- [ ] Messages dropped or queued when buffer is full

Scaling:
- [ ] Redis pub/sub for multi-instance broadcasts
- [ ] Connection count monitored as a metric

Security:
- [ ] Origin validation on WebSocket upgrade
- [ ] Message size limit enforced
- [ ] Rate limiting on message frequency per connection
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Auth inside first WebSocket message | Auth during HTTP upgrade, before connection is accepted |
| No heartbeat — stale connections accumulate | ping/pong every 30s, terminate if no pong |
| Reconnect immediately on close | Exponential backoff with jitter |
| Sending to `ws.send()` without checking bufferedAmount | Check backpressure threshold first |
| In-process connection registry — breaks with multiple instances | Redis pub/sub for cross-instance broadcast |
| Using WebSocket for unidirectional server push | SSE — simpler, HTTP-native, auto-reconnect |

## Connected Skills

- `observability` — track connection count, message rate, and reconnect frequency as metrics
- `error-handling` — WebSocket error handling follows the same boundary translation principles
- `security-hardening` — origin validation, rate limiting per connection, message size limits
- `python-fastapi` — FastAPI SSE streaming for thesis LLM response streaming
- `message-queue` — for guaranteed delivery, use a queue instead of direct WebSocket push

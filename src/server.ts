import express, { Request, Response } from 'express';

const app = express();
const port = process.env.PORT || 3000;
const version = process.env.APP_VERSION || 'v1';

// Simulate startup delay for readiness probe demonstration
const STARTUP_DELAY = 5000; // 5 seconds
let isReady = false;

setTimeout(() => {
  isReady = true;
  console.log(`App (${version}) is ready to accept traffic.`);
}, STARTUP_DELAY);

app.get('/health', (req: Request, res: Response) => {
  if (isReady) {
    res.status(200).json({ status: 'ok', version });
  } else {
    res.status(503).json({ status: 'starting', version });
  }
});

app.get('/version', (req: Request, res: Response) => {
  res.status(200).json({ version });
});

app.get('/', (req: Request, res: Response) => {
  res.send(`Hello from Backend ${version}!`);
});


const server = app.listen(port, () => {
  console.log(`Backend ${version} listening on port ${port}`);
});

// Graceful Shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

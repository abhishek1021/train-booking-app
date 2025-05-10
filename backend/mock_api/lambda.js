const jsonServer = require('json-server');
const serverlessExpress = require('@vendia/serverless-express');

// Set up json-server
const server = jsonServer.create();
const router = jsonServer.router('db.json'); // Make sure db.json exists in this folder
const middlewares = jsonServer.defaults();

server.use(middlewares);

// Logging middleware
server.use((req, res, next) => {
  console.log(`[MOCK API] ${req.method} ${req.url} from ${req.headers['x-forwarded-for'] || req.connection.remoteAddress}`);
  next();
});

server.use(router);

// Export the Lambda handler
exports.handler = serverlessExpress({ app: server });

import express from 'express';
import routes from './routes/index.js';
import { appConfig } from './config/index.js';
import { logger } from './utils/logger.js';

const app = express();

app.use(express.json());
app.use('/api', routes);

const start = () => {
  app.listen(appConfig.port, () => {
    logger.info(`Rush BFF running on port ${appConfig.port} in ${appConfig.nodeEnv} mode`);
  });
};

start();

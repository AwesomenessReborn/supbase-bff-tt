import { Router } from 'express';
import { getHealthStatus } from '../services/health/index.js';

export const registerHealthRoutes = (router: Router): void => {
  router.get('/health', (_req, res) => {
    res.json(getHealthStatus());
  });
};

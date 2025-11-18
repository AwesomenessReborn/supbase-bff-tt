import { Router } from 'express';
import { registerHealthRoutes } from './health.js';

const router = Router();

registerHealthRoutes(router);

export default router;

// src/test-prisma.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testPrisma() {
  // Get all users
  const users = await prisma.public_users.findMany({
    take: 5  // Get first 5
  });
  
  console.log('Users:', users);
}

testPrisma()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
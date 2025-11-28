import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const pet = await prisma.pet.findUnique({
    where: { id: '8ea148df-b378-400b-8bc9-0946eae03264' },
    select: {
      id: true,
      userId: true,
      name: true,
    },
  });

  console.log('Pet data:', pet);
  console.log('userId type:', typeof pet?.userId);
  console.log('userId value:', pet?.userId);

  // Also get the JWT user ID for comparison
  const jwtUserId = 'e4291e57-3f22-4639-8cae-31c70dba2928';
  console.log('\nJWT userId:', jwtUserId);
  console.log('JWT userId type:', typeof jwtUserId);
  console.log('Are they equal?:', pet?.userId === jwtUserId);
  console.log('String comparison:', String(pet?.userId) === String(jwtUserId));
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

const test = require('node:test');
const assert = require('node:assert/strict');

test('env example keeps safe production defaults explicit', async () => {
  const fs = require('node:fs/promises');
  const content = await fs.readFile('.env.example', 'utf8');
  assert.match(content, /^JWT_SECRET=/m);
  assert.match(content, /^TYPEORM_SYNC=true/m);
  assert.match(content, /^SEED_ADMIN=true/m);
});

const test = require('node:test');
const assert = require('node:assert/strict');

function resolveOrderScopeUserId(req, kitchenMode) {
  if (kitchenMode) return undefined;
  const perms = req?.user?.permissions ?? [];
  if (perms.includes('finance.view')) return undefined;
  return req?.user?.id;
}

test('orders scope returns undefined for finance role', () => {
  const scoped = resolveOrderScopeUserId(
    { user: { id: 'u1', permissions: ['finance.view'] } },
    false,
  );
  assert.equal(scoped, undefined);
});

test('orders scope restricts to current user without finance permission', () => {
  const scoped = resolveOrderScopeUserId(
    { user: { id: 'u2', permissions: ['pos.access'] } },
    false,
  );
  assert.equal(scoped, 'u2');
});

test('kitchen mode bypasses user scope', () => {
  const scoped = resolveOrderScopeUserId(
    { user: { id: 'u3', permissions: [] } },
    true,
  );
  assert.equal(scoped, undefined);
});

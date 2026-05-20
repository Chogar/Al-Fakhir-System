export type OrderPayload = {
  serviceType: string;
  diningTableId?: string | null;
  items: Array<{ productId: string; quantity: number }>;
};

export function validateOrderPayload(payload: OrderPayload): string | null {
  if (!payload.items?.some((line) => line.quantity > 0)) {
    return 'Au moins un article est requis';
  }
  if (
    payload.serviceType === 'DINE_IN' &&
    (!payload.diningTableId || payload.diningTableId.trim().length === 0)
  ) {
    return 'Une table est obligatoire pour le service sur place';
  }
  return null;
}

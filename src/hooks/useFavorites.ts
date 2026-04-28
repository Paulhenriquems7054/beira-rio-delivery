import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useTenant } from "@/contexts/TenantContext";
import { listFavorites, toggleFavorite } from "@/services/favoritesApi";

export interface Favorite {
  id: string;
  tenantId: string;
  customerPhone: string;
  productId: string;
  createdAt: string;
}

function requireTenantId(tenantId?: string): string {
  if (!tenantId) {
    throw new Error("TenantContext ausente: store.id é obrigatório para usar favoritos.");
  }
  return tenantId;
}

export function useFavorites(customerPhone?: string) {
  const { store } = useTenant();
  const tenantId = store?.id;

  return useQuery({
    queryKey: ["favorites", customerPhone, tenantId],
    queryFn: async () => {
      if (!customerPhone) return [];
      const ensuredTenantId = requireTenantId(tenantId);
      return listFavorites({ customerPhone, tenantId: ensuredTenantId });
    },
    enabled: !!customerPhone,
  });
}

export function useToggleFavorite() {
  const { store } = useTenant();
  const tenantId = store?.id;
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ customerPhone, productId }: { customerPhone: string; productId: string }) => {
      const ensuredTenantId = requireTenantId(tenantId);
      const response = await toggleFavorite({ customerPhone, productId, tenantId: ensuredTenantId });
      return response.data;
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ["favorites", variables.customerPhone, tenantId] });
    },
  });
}

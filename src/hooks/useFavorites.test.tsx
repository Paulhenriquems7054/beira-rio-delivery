import { beforeEach, describe, expect, it, vi } from "vitest";

const useTenantMock = vi.fn();
const listFavoritesMock = vi.fn();
const toggleFavoriteMock = vi.fn();
const useQueryMock = vi.fn();
const useMutationMock = vi.fn();
const useQueryClientMock = vi.fn();

vi.mock("@tanstack/react-query", () => ({
  useQuery: (...args: unknown[]) => useQueryMock(...args),
  useMutation: (...args: unknown[]) => useMutationMock(...args),
  useQueryClient: () => useQueryClientMock(),
}));

vi.mock("@/contexts/TenantContext", () => ({
  useTenant: () => useTenantMock(),
}));

vi.mock("@/services/favoritesApi", () => ({
  listFavorites: (...args: unknown[]) => listFavoritesMock(...args),
  toggleFavorite: (...args: unknown[]) => toggleFavoriteMock(...args),
}));

describe("useFavorites strict tenant guard", () => {
  beforeEach(() => {
    useTenantMock.mockReset();
    listFavoritesMock.mockReset();
    toggleFavoriteMock.mockReset();
    useQueryMock.mockReset();
    useMutationMock.mockReset();
    useQueryClientMock.mockReset();
    useQueryClientMock.mockReturnValue({ invalidateQueries: vi.fn() });
  });

  it("falha com erro explicito quando store.id está ausente no useFavorites", async () => {
    useTenantMock.mockReturnValue({ store: null, isLoading: false, refresh: vi.fn() });
    useQueryMock.mockImplementation(({ queryFn }: { queryFn: () => Promise<unknown> }) => ({
      execute: queryFn,
    }));

    const { useFavorites } = await import("@/hooks/useFavorites");
    const result = useFavorites("+5511999999999") as { execute: () => Promise<unknown> };
    await expect(result.execute()).rejects.toThrow(
      "TenantContext ausente: store.id é obrigatório para usar favoritos.",
    );
    expect(listFavoritesMock).not.toHaveBeenCalled();
  });

  it("falha com erro explicito quando store.id está ausente no useToggleFavorite", async () => {
    useTenantMock.mockReturnValue({ store: null, isLoading: false, refresh: vi.fn() });
    useMutationMock.mockImplementation(({ mutationFn }: { mutationFn: (payload: unknown) => Promise<unknown> }) => ({
      mutateAsync: mutationFn,
    }));

    const { useToggleFavorite } = await import("@/hooks/useFavorites");
    const result = useToggleFavorite() as { mutateAsync: (payload: unknown) => Promise<unknown> };

    await expect(
      result.mutateAsync({
        customerPhone: "+5511999999999",
        productId: "550e8400-e29b-41d4-a716-446655440000",
      }),
    ).rejects.toThrow("TenantContext ausente: store.id é obrigatório para usar favoritos.");

    expect(toggleFavoriteMock).not.toHaveBeenCalled();
  });
});

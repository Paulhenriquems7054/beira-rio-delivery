import { FavoritesController } from "@/backend/controllers/favorites.controller";
import { SupabaseFavoritesRepository } from "@/backend/repositories/supabase/supabase-favorites.repository";
import { FavoritesService } from "@/backend/services/favorites.service";
import { supabase } from "@/integrations/supabase/client";

const favoritesRepository = new SupabaseFavoritesRepository(supabase);
const favoritesService = new FavoritesService(favoritesRepository);
export const favoritesController = new FavoritesController(favoritesService);

/**
 * Exemplo de uso em endpoint Express/Fastify:
 *
 * app.post("/api/favorites/toggle", async (req, res) => {
 *   const result = await favoritesController.toggle({
 *     body: req.body,
 *     params: {},
 *     context: {
 *       userId: req.user.id,
 *       tenantId: req.headers["x-tenant-id"],
 *       role: req.user.role,
 *       requestId: req.id
 *     }
 *   });
 *   res.status(result.status).json(result.body);
 * });
 */

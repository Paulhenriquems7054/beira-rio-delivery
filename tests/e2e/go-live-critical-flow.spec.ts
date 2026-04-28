import { expect, test } from "../../playwright-fixture";

const BASE_URL = process.env.E2E_BASE_URL;
const STORE_SLUG = process.env.E2E_STORE_SLUG;
const ADMIN_URL = process.env.E2E_ADMIN_URL;
const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD;

test.describe("go-live critical flow", () => {
  test("cliente fecha checkout com carrinho misto", async ({ page }) => {
    test.skip(!BASE_URL || !STORE_SLUG, "Defina E2E_BASE_URL e E2E_STORE_SLUG");

    await page.goto(`${BASE_URL}/${STORE_SLUG}`);
    await expect(page.getByText("Monte sua Cesta")).toBeVisible();

    await page.getByRole("button", { name: /Adicionar/i }).first().click();
    await page.getByRole("button", { name: /Ir p\/ Checkout/i }).click();

    await page.getByPlaceholder("Ex: Maria da Silva").fill("Cliente Teste");
    await page.getByPlaceholder("(00) 00000-0000").fill("(11) 99999-9999");
    await page.getByPlaceholder("Rua / Avenida / Travessa").fill("Rua Teste");
    await page.getByPlaceholder("Número").fill("123");
    await page.getByPlaceholder("Bairro").fill("Centro");

    await page.getByRole("button", { name: /Confirmar Pedido/i }).click();
    await expect(page.getByText("Pedido enviado")).toBeVisible();
  });

  test("admin acompanha pedidos e tela do entregador", async ({ page }) => {
    test.skip(
      !BASE_URL || !ADMIN_URL || !ADMIN_EMAIL || !ADMIN_PASSWORD,
      "Defina E2E_BASE_URL, E2E_ADMIN_URL, E2E_ADMIN_EMAIL e E2E_ADMIN_PASSWORD",
    );

    await page.goto(ADMIN_URL);
    await page.getByPlaceholder(/email/i).fill(ADMIN_EMAIL!);
    await page.getByPlaceholder(/senha/i).fill(ADMIN_PASSWORD!);
    await page.getByRole("button", { name: /entrar|login/i }).click();

    await expect(page.getByText("Painel")).toBeVisible();
    await expect(page.getByText("Tela do Entregador")).toBeVisible();

    const deliveryLink = page.locator("a").filter({ hasText: /\/delivery$/ }).first();
    await expect(deliveryLink).toBeVisible();
  });
});

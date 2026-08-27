import assert from "node:assert/strict";
import test from "node:test";

Object.assign(globalThis, {
  L: {
    rpc: {
      declare: () => async () => ({}),
    },
  },
});

const { fetchLatestRelease, matchI18nAsset, UPDATE_REPOSITORY } = await import("./update");

const releaseAsset = (name: string, digest = "sha256:abc") => ({
  url: "",
  id: 1,
  node_id: "",
  name,
  label: "",
  uploader: {
    login: "",
    id: 1,
    node_id: "",
    avatar_url: "",
    gravatar_id: "",
    url: "",
    html_url: "",
    followers_url: "",
    following_url: "",
    gists_url: "",
    starred_url: "",
    subscriptions_url: "",
    organizations_url: "",
    repos_url: "",
    events_url: "",
    received_events_url: "",
    type: "User",
    user_view_type: "public",
    site_admin: false,
  },
  content_type: "application/octet-stream",
  state: "uploaded",
  size: 42,
  digest,
  download_count: 0,
  created_at: new Date(),
  updated_at: new Date(),
  browser_download_url: `https://github.com/${UPDATE_REPOSITORY}/releases/download/nightly/${name}`,
});

test("updater targets this fork and selects matching IPK assets", async () => {
  const requested: { url?: string; headers?: HeadersInit } = {};
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (input, init) => {
    requested.url = String(input);
    requested.headers = init?.headers;
    return new Response(
      JSON.stringify({
        tag_name: "nightly",
        published_at: "2026-08-27T00:00:00Z",
        body: "Nightly build",
        html_url: `https://github.com/${UPDATE_REPOSITORY}/releases/tag/nightly`,
        assets: [releaseAsset("luci-theme-fluent_1.0.9_all.ipk"), releaseAsset("luci-i18n-fluent-pt-br_1.0.9_all.ipk")],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  };

  try {
    const result = await fetchLatestRelease("nightly", "ipk", ["pt-br"]);
    assert.equal(requested.url, `https://api.github.com/repos/${UPDATE_REPOSITORY}/releases/tags/nightly`);
    assert.deepEqual(requested.headers, {
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    });
    assert.equal(result.package_asset?.name, "luci-theme-fluent_1.0.9_all.ipk");
    assert.deepEqual(
      result.i18n_assets.map((asset) => asset.name),
      ["luci-i18n-fluent-pt-br_1.0.9_all.ipk"],
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("translation matching is package-format specific", () => {
  const assets = [releaseAsset("luci-i18n-fluent-pt-br_1.0.9_all.ipk"), releaseAsset("luci-i18n-fluent-pt-br-1.0.9.apk")];

  assert.equal(matchI18nAsset(assets, "PT-BR", "ipk")?.name, "luci-i18n-fluent-pt-br_1.0.9_all.ipk");
  assert.equal(matchI18nAsset(assets, "pt-br", "apk")?.name, "luci-i18n-fluent-pt-br-1.0.9.apk");
});

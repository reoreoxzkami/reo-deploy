// 動的サイトの例: /api/* はサーバー処理、それ以外は public/ の静的ファイル
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/api/hello") {
      return Response.json({ message: "こんにちは！", time: new Date().toISOString() });
    }
    return env.ASSETS.fetch(request);
  },
};

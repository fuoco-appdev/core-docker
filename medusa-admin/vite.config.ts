import path from "path"
import dns from "dns"
import { defineConfig, loadEnv } from "vite"
import react from "@vitejs/plugin-react"

// Resolve localhost for Node v16 and older.
// @see https://vitejs.dev/config/server-options.html#server-host.
dns.setDefaultResultOrder("verbatim")

export default ({ mode }) => {
  process.env = { ...process.env, ...loadEnv(mode, process.cwd()) }

  // import.meta.env.VITE_NAME available here with: process.env.VITE_NAME
  // import.meta.env.VITE_PORT available here with: process.env.VITE_PORT

  return defineConfig({
    plugins: [react()],
    // Backwards-compat with Gatsby.
    publicDir: "static",
    server: {
      port: 7000,
      host: true,
    },
    define: {
      __MEDUSA_BACKEND_URL__: JSON.stringify(process.env.MEDUSA_BACKEND_URL),
    },
    build: {
      outDir: "public",
    },
    resolve: {
      alias: {
        gatsby: path.resolve(__dirname, "src/compat/gatsby-compat.tsx"),
        "@reach/router": path.resolve(
          __dirname,
          "src/compat/reach-router-compat.tsx"
        ),
      },
    },
    optimizeDeps: {
      exclude: ["typeorm", "medusa-interfaces"],
    },
  })
}

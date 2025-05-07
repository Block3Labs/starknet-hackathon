/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_DEFAULT_MARKET: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
} 
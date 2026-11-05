import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  base: './',
  build: { outDir: 'dist', emptyOutDir: true, assetsInlineLimit: 0 },
  server: { port: 5190, host: '127.0.0.1' },
});

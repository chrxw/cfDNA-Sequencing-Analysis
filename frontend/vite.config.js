import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/static/',
  // build: {
  //   rollupOptions: {
  //     external: ['axios', 'react-router-dom', 'antd', 'styled-components'],
  //   },
  // },
})

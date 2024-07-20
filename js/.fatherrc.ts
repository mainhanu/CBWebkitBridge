import { defineConfig } from 'father';

export default defineConfig({
  esm: {},
  umd: {
    chainWebpack: (config) => {
      config.optimization.minimize(false)

      return config;
    }
  }
});

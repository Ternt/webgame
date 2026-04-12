import { defineConfig } from '@rsbuild/core';

export default defineConfig({
  source: { 
    entry: { 
      index: './code/web/index.js', 
    } 
  },
  html: { 
    title: "Web Game",
    template: './code/web/index.html',
  },
  output: {
    distPath: "./build/web",
  },
  devServer: {
    allowedHosts: 'all',
    client: {
      progress: true,
      logging: 'info',
      overlay: {
        errors: true,
        warnings: false,
        runtimeErrors: true,
      },
    },
  },
});

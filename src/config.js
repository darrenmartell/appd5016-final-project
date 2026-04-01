// Centralized config file
const config = {
  API_URL: import.meta.env.VITE_API_ENDPOINT || "http://localhost:3000"
};

export default config;
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    // React app
    "./src/**/*.{js,jsx}",
    // Blazor app
    "./blazor-migration/**/*.{razor,html}",
  ],
  theme: {
    extend: {
      colors: {
        // Netflix-style dark theme
        surface: {
          0: "#0f0f10",
          1: "#171718",
          2: "#1f1f21",
          3: "#2a2a2d",
        },
        text: {
          0: "#fbfbfb",
          1: "#d0d0d2",
          2: "#a0a0a5",
        },
        accent: "#e50914",
        "accent-strong": "#b20710",
        border: "#323237",
      },
      backgroundColor: {
        dark: "#141414",
        card: "rgba(34, 34, 36, 0.95)",
      },
      borderColor: {
        primary: "#313136",
      },
      boxShadow: {
        netflix: "0 1.25rem 2.75rem rgba(0, 0, 0, 0.28)",
        accent: "0 0.8rem 2rem rgba(229, 9, 20, 0.16)",
      },
      fontSize: {
        eyebrow: ["0.72rem", { letterSpacing: "0.18em", fontWeight: "700" }],
      },
    },
  },
  plugins: [],
};

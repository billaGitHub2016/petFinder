/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    esmExternals: "loose",
  },
  images: {
    // remotePatterns: [
    //   {
    //     protocol: 'https',
    //     hostname: 'rlscyjecgizuupwobasc.supabase.co',
    //     port: '',
    //     pathname: '/storage/v1/object/public/task_images/**',
    //     search: '',
    //   },
    // ],
    domains: ["image.billa4161.xyz"],
    remotePatterns: [
      {
        protocol: "https",
        hostname: "image.billa4161.xyz",
      },
    ],
  },
};

module.exports = nextConfig;

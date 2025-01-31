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
    // domains: ["image.billa4161.xyz", "pbs.twimg.com"],
    remotePatterns: [
      {
        protocol: "https",
        hostname: "image.billa4161.xyz",
      },
      {
        protocol: "https",
        hostname: "pbs.twimg.com",
      },
    ],
  },
};

module.exports = nextConfig;

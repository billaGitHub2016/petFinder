const service = ({ strapi }) => ({
  getWelcomeMessage() {
    return 'Welcome to Strapi 🚀';
  },
  async getPetApply(documentId) {
    return strapi.query('plugin::contract-strapi-plugin.pet-apply').find({
      documentId
    });
  },
});

export default service;

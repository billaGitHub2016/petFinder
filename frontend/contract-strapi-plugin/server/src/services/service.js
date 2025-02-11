const service = ({ strapi }) => ({
  getWelcomeMessage() {
    return 'Welcome to Strapi 🚀';
  },
  async getPetApply(documentId) {
    return strapi.query('plugin::contract-strapi-plugin.pet-apply').find({
      documentId
    });
  },
  async createContract(data) {
    return strapi.documents('plugin::contract-strapi-plugin.contract').create({ data });
  },
});

export default service;

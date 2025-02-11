const service = ({ strapi }) => ({
  getWelcomeMessage() {
    return 'Welcome to Strapi 🚀';
  },
  async getPetApply(documentId) {
    // return strapi.query('plugin::contract-strapi-plugin.pet-apply').find({
    //   documentId
    // });
    return strapi.db.query('api::pet-apply.pet-apply').findMany({
      where: {
        // Only pass the related ID if it's pointing to a collection type
        documentId
      },
    });
  },
  async createContract(data) {
    return strapi.documents('plugin::contract-strapi-plugin.contract').create({ data });
  },
});

export default service;

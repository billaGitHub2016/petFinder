const service = ({ strapi }) => ({
  getWelcomeMessage() {
    return 'Welcome to Strapi 🚀';
  },
  async getPetApply(documentId) {
    // console.log('~~~~~~~~~~~~~~~~documentId', documentId);
    const result = await strapi.db.query('api::pet-apply.pet-apply').findOne({
      where: { document_id: documentId },
      // populate: {
      //   pet: true,
      // }
      populate: true,
    });
    return result;
    // return strapi.db.query('api::pet-apply.pet-apply').findMany({
    //   where: {
    //     // Only pass the related ID if it's pointing to a collection type
    //     document_id: documentId,
    //   },
    // });
  },
  async createContract(data) {
    const result = await strapi
      .documents('api::pet-contract.pet-contract')
      .create({ data, status: data.status });
    console.log('createContract result = ', result);
    return result;
  },
});

export default service;

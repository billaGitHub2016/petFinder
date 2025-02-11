const controller = ({ strapi }) => ({
  index(ctx) {
    ctx.body = strapi
      .plugin('contract-strapi-plugin')
      // the name of the service file & the method.
      .service('service')
      .getWelcomeMessage();
  },
  getPetApply(ctx) {
    ctx.body = strapi.plugin('contract-strapi-plugin').service('service').getPetApply(ctx.params.documentId);
  },
  createContract(ctx) {
    ctx.body = strapi.plugin('contract-strapi-plugin').service('service').createContract(ctx.request.body);
  }
});

export default controller;

const controller = ({ strapi }) => ({
  index(ctx) {
    ctx.body = strapi
      .plugin('contract-strapi-plugin')
      // the name of the service file & the method.
      .service('service')
      .getWelcomeMessage();
  },
  getPetApply(ctx) {
    return strapi.plugin('contract-strapi-plugin').service('service').getPetApply(ctx.query.documentId);
  },
  createContract(ctx) {
    console.log('createContract ctx.request.body = ', ctx.request.body);
    ctx.body = strapi.plugin('contract-strapi-plugin').service('service').createContract(ctx.request.body);
  }
});

export default controller;

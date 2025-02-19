const bootstrap = ({ strapi }) => {
};
const destroy = ({ strapi }) => {
};
const register = ({ strapi }) => {
};
const config = {
  default: {},
  validator() {
  }
};
const contentTypes = {};
const controller = ({ strapi }) => ({
  index(ctx) {
    ctx.body = strapi.plugin("contract-strapi-plugin").service("service").getWelcomeMessage();
  },
  getPetApply(ctx) {
    return strapi.plugin("contract-strapi-plugin").service("service").getPetApply(ctx.query.documentId);
  },
  createContract(ctx) {
    ctx.body = strapi.plugin("contract-strapi-plugin").service("service").createContract(ctx.request.body);
  },
  getRecord(ctx) {
    return strapi.plugin("contract-strapi-plugin").service("service").getRecord(ctx.query.documentId);
  },
  updateRecord(ctx) {
    ctx.body = strapi.plugin("contract-strapi-plugin").service("service").updateRecord(ctx.request.body);
  },
  updateContract(ctx) {
    ctx.body = strapi.plugin("contract-strapi-plugin").service("service").updateContract(ctx.request.body);
  },
  getRecordsByContract(ctx) {
    return strapi.plugin("contract-strapi-plugin").service("service").getRecordsByContract(ctx.query.contractId);
  }
});
const controllers = {
  controller
};
const middlewares = {};
const policies = {};
const routes = [
  {
    method: "GET",
    path: "/",
    // name of the controller file & the method.
    handler: "controller.index",
    config: {
      policies: []
    }
  },
  {
    method: "GET",
    path: "/getPetApply/:slug",
    // name of the controller file & the method.
    handler: "controller.getPetApply",
    config: {
      policies: []
    }
  },
  {
    method: "GET",
    path: "/getRecord/:slug",
    // name of the controller file & the method.
    handler: "controller.getRecord",
    config: {
      policies: []
    }
  },
  {
    method: "POST",
    path: "/contracts",
    // name of the controller file & the method.
    handler: "controller.createContract",
    config: {
      policies: []
    }
  },
  {
    method: "PUT",
    path: "/contracts",
    // name of the controller file & the method.
    handler: "controller.updateContract",
    config: {
      policies: []
    }
  },
  {
    method: "PUT",
    path: "/records",
    // name of the controller file & the method.
    handler: "controller.updateRecord",
    config: {
      policies: []
    }
  },
  {
    method: "GET",
    path: "/getRecordsByContract/:slug",
    // name of the controller file & the method.
    handler: "controller.getRecordsByContract",
    config: {
      policies: []
    }
  }
];
const service = ({ strapi }) => ({
  getWelcomeMessage() {
    return "Welcome to Strapi 🚀";
  },
  async getPetApply(documentId) {
    const result = await strapi.db.query("api::pet-apply.pet-apply").findOne({
      where: { document_id: documentId },
      populate: true
    });
    return result;
  },
  async getRecord(documentId) {
    const result = await strapi.db.query("api::record.record").findOne({
      where: { document_id: documentId },
      populate: true
    });
    console.log("getRecord result = ", result);
    return result;
  },
  async createContract(data) {
    const result = await strapi.documents("api::pet-contract.pet-contract").create({ data, status: data.status });
    console.log("createContract result = ", result);
    return result;
  },
  async updateContract(data) {
    const result = await strapi.documents("api::pet-contract.pet-contract").update({ documentId: data.documentId, data: data.data, status: data.status });
    console.log("updateContract result = ", result);
    return result;
  },
  async updateRecord(data) {
    const result = await strapi.documents("api::record.record").update({
      documentId: data.documentId,
      data: data.data,
      status: data.status
    });
    console.log("updateRecord result = ", result);
    return result;
  },
  async getRecordsByContract(contractId) {
    console.log("getRecordsByContract contractId = ", contractId);
    const result = await strapi.db.query("api::record.record").findMany({
      filters: {
        contract: {
          documentId: contractId
        },
        result: "Pass",
        publishedAt: {
          $notNull: true
        }
      },
      status: "published"
    });
    return result;
  }
});
const services = {
  service
};
const index = {
  bootstrap,
  destroy,
  register,
  config,
  controllers,
  contentTypes,
  middlewares,
  policies,
  routes,
  services
};
export {
  index as default
};
//# sourceMappingURL=index.mjs.map

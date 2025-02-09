export default [
  {
    method: 'GET',
    path: '/',
    // name of the controller file & the method.
    handler: 'controller.index',
    config: {
      policies: [],
    },
  },
  {
    method: 'GET',
    path: '/getPetApply',
    // name of the controller file & the method.
    handler: 'controller.getPetApply',
    config: {
      policies: [],
    },
  },
];

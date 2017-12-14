
var FilterBoxComponents = {
  helpers: {},
  shared_elements: {},
  create: function(options){
    var fieldFactoryName = options.field_type + '_filter_component';
    //try {
    return this[fieldFactoryName](options);
    //} catch (e) {
      //console.error(e)
      //throw('FilterComponent.createError: ' + e + '. The most likely fix is to create a function in "FilterComponents" named "' + fieldFactoryName + '(options)" that returns a filter component HTML.')
    //}
  }
};

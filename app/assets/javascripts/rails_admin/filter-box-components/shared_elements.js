(function(components){

  var shared_elements = components.shared_elements;
  var helpers = components.helpers;

  shared_elements.between_and_default_options = function (options) {
    var r = '';
    r += '<option ' + helpers.default_operator_selected(options) + ' data-additional-fieldset="default" value="default">' + (options.field_type == "date" ? RailsAdmin.I18n.t("date") : RailsAdmin.I18n.t("number")) + '</option>'
    r += '<option ' + helpers.between_operator_selected(options) + ' data-additional-fieldset="between" value="between">' + RailsAdmin.I18n.t("between_and_") + '</option>';
    return r;
  }

}(FilterBoxComponents));

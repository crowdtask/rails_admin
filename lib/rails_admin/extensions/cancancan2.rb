require 'rails_admin/extensions/cancancan/authorization_adapter'

RailsAdmin.add_extension(:cancancan2, RailsAdmin::Extensions::CanCanCan2, authorization: true)
